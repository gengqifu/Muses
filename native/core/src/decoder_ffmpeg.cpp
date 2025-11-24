#include "decoder.h"

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>
#include <libavutil/channel_layout.h>
}

#include <algorithm>
#include <memory>
#include <string>
#include <vector>

namespace sw {

namespace {

AVSampleFormat NormalizeSampleFormat(AVSampleFormat fmt) {
  // Prefer float planar/interleaved; otherwise fall back to 16-bit signed.
  switch (fmt) {
    case AV_SAMPLE_FMT_FLTP:
    case AV_SAMPLE_FMT_FLT:
      return fmt;
    default:
      return AV_SAMPLE_FMT_S16;
  }
}

class DecoderFFmpeg : public Decoder {
 public:
  ~DecoderFFmpeg() override { Close(); }

  bool Open(const std::string& source) override {
    Close();
    if (source.empty()) {
      last_status_ = Status::kInvalidArguments;
      return false;
    }
    // Temporary holders to ensure cleanup on failure.
    AVFormatContext* fmt = avformat_alloc_context();
    if (avformat_open_input(&fmt, source.c_str(), nullptr, nullptr) < 0) {
      avformat_free_context(fmt);
      last_status_ = Status::kIoError;
      return false;
    }
    if (avformat_find_stream_info(fmt, nullptr) < 0) {
      avformat_close_input(&fmt);
      last_status_ = Status::kError;
      return false;
    }
    int stream_idx = av_find_best_stream(fmt, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    if (stream_idx < 0) {
      avformat_close_input(&fmt);
      last_status_ = Status::kNotSupported;
      return false;
    }
    AVStream* stream = fmt->streams[stream_idx];
    const AVCodec* codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (!codec) {
      avformat_close_input(&fmt);
      last_status_ = Status::kNotSupported;
      return false;
    }
    AVCodecContext* cctx = avcodec_alloc_context3(codec);
    if (!cctx) {
      avformat_close_input(&fmt);
      last_status_ = Status::kError;
      return false;
    }
    if (avcodec_parameters_to_context(cctx, stream->codecpar) < 0) {
      avcodec_free_context(&cctx);
      avformat_close_input(&fmt);
      last_status_ = Status::kError;
      return false;
    }
    if (avcodec_open2(cctx, codec, nullptr) < 0) {
      avcodec_free_context(&cctx);
      avformat_close_input(&fmt);
      last_status_ = Status::kError;
      return false;
    }
    // Configure output.
    sample_rate_ = target_sample_rate_ > 0 ? target_sample_rate_ : cctx->sample_rate;
    channels_ = target_channels_ > 0 ? target_channels_ : cctx->ch_layout.nb_channels;
    if (channels_ == 0) {
      channels_ = 2;
    }
    // Build output channel layout.
    AVChannelLayout out_layout;
    av_channel_layout_default(&out_layout, channels_);
    AVSampleFormat out_fmt = AV_SAMPLE_FMT_FLT;
    SwrContext* swr = nullptr;
    if (swr_alloc_set_opts2(&swr,
                            &out_layout,
                            out_fmt,
                            sample_rate_,
                            &cctx->ch_layout,
                            cctx->sample_fmt,
                            cctx->sample_rate,
                            0,
                            nullptr) < 0) {
      avcodec_free_context(&cctx);
      avformat_close_input(&fmt);
      last_status_ = Status::kError;
      return false;
    }
    if (!swr || swr_init(swr) < 0) {
      swr_free(&swr);
      avcodec_free_context(&cctx);
      avformat_close_input(&fmt);
      last_status_ = Status::kError;
      return false;
    }
    AVFrame* frame = av_frame_alloc();
    AVPacket* packet = av_packet_alloc();
    if (!frame || !packet) {
      av_frame_free(&frame);
      av_packet_free(&packet);
      swr_free(&swr);
      avcodec_free_context(&cctx);
      avformat_close_input(&fmt);
      last_status_ = Status::kError;
      return false;
    }
    // Success: assign to members.
    fmt_ctx_ = fmt;
    codec_ctx_ = cctx;
    swr_ctx_ = swr;
    frame_ = frame;
    packet_ = packet;
    audio_stream_idx_ = stream_idx;
    opened_ = true;
    last_status_ = Status::kOk;
    return true;
  }

  bool Read(PcmBuffer& out_buffer) override {
    if (!opened_) {
      last_status_ = Status::kInvalidState;
      return false;
    }
    while (true) {
      int ret = av_read_frame(fmt_ctx_, packet_);
      if (ret < 0) {
        // Flush decoder on EOF.
        avcodec_send_packet(codec_ctx_, nullptr);
        ret = avcodec_receive_frame(codec_ctx_, frame_);
        if (ret == AVERROR_EOF) {
          last_status_ = Status::kOk;
          return false;
        }
      } else if (packet_->stream_index != audio_stream_idx_) {
        av_packet_unref(packet_);
        continue;
      } else {
        if (avcodec_send_packet(codec_ctx_, packet_) < 0) {
          av_packet_unref(packet_);
          last_status_ = Status::kError;
          return false;
        }
        av_packet_unref(packet_);
        ret = avcodec_receive_frame(codec_ctx_, frame_);
      }

      if (ret == AVERROR(EAGAIN)) {
        continue;
      }
      if (ret < 0) {
        last_status_ = Status::kError;
        return false;
      }

      // Resample to interleaved float.
      int64_t delay = swr_get_delay(swr_ctx_, codec_ctx_->sample_rate);
      int out_samples = swr_get_out_samples(swr_ctx_, frame_->nb_samples);
      out_samples += av_rescale_rnd(delay, sample_rate_, codec_ctx_->sample_rate, AV_ROUND_UP);
      if (out_samples <= 0) {
        out_samples = frame_->nb_samples > 0 ? frame_->nb_samples : 1024;
      }
      out_buffer.interleaved.resize(static_cast<size_t>(out_samples * channels_));
      uint8_t* out_data[1] = {
          reinterpret_cast<uint8_t*>(out_buffer.interleaved.data()),
      };
      int converted = swr_convert(swr_ctx_,
                                  out_data,
                                  out_samples,
                                  const_cast<const uint8_t**>(frame_->data),
                                  frame_->nb_samples);
      if (converted < 0) {
        last_status_ = Status::kError;
        return false;
      }
      out_buffer.interleaved.resize(static_cast<size_t>(converted * channels_));
      out_buffer.sample_rate = sample_rate_;
      out_buffer.channels = channels_;
      last_status_ = Status::kOk;
      return true;
    }
  }

  void Close() override {
    if (packet_) {
      av_packet_free(&packet_);
    }
    if (frame_) {
      av_frame_free(&frame_);
    }
    if (swr_ctx_) {
      swr_free(&swr_ctx_);
    }
    if (codec_ctx_) {
      avcodec_free_context(&codec_ctx_);
    }
    if (fmt_ctx_) {
      avformat_close_input(&fmt_ctx_);
    }
    opened_ = false;
  }

  int sample_rate() const override { return sample_rate_; }
  int channels() const override { return channels_; }

  bool ConfigureOutput(int target_sample_rate, int target_channels) override {
    if (target_sample_rate <= 0 || target_channels <= 0) {
      last_status_ = Status::kInvalidArguments;
      return false;
    }
    target_sample_rate_ = target_sample_rate;
    target_channels_ = target_channels;
    last_status_ = Status::kOk;
    return true;
  }

  Status last_status() const override { return last_status_; }

 private:
  AVFormatContext* fmt_ctx_ = nullptr;
  AVCodecContext* codec_ctx_ = nullptr;
  SwrContext* swr_ctx_ = nullptr;
  AVFrame* frame_ = nullptr;
  AVPacket* packet_ = nullptr;
  int audio_stream_idx_ = -1;
  int target_sample_rate_ = 0;
  int target_channels_ = 0;
  int sample_rate_ = 48000;
  int channels_ = 2;
  bool opened_ = false;
  Status last_status_ = Status::kOk;
};

}  // namespace

std::unique_ptr<Decoder> CreateFFmpegDecoder() {
  return std::make_unique<DecoderFFmpeg>();
}

}  // namespace sw
