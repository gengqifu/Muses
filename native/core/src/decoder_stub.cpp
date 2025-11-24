#include "decoder.h"

#include <algorithm>

namespace sw {

class DecoderStub : public Decoder {
 public:
  bool Open(const std::string& source) override {
    if (source.empty()) {
      return false;
    }
    if (!IsSupported(source)) {
      return false;
    }
    opened_ = true;
    return true;
  }
  bool Read(PcmBuffer& out_buffer) override {
    if (!opened_) {
      return false;
    }
    out_buffer.interleaved.clear();
    out_buffer.sample_rate = sample_rate_;
    out_buffer.channels = channels_;
    return false;  // EOF immediately.
  }
  void Close() override {}

  int sample_rate() const override { return sample_rate_; }
  int channels() const override { return channels_; }

  bool ConfigureOutput(int target_sample_rate, int target_channels) override {
    if (target_sample_rate <= 0 || target_channels <= 0) {
      return false;
    }
    sample_rate_ = target_sample_rate;
    channels_ = target_channels;
    return true;
  }

 private:
  bool IsSupported(const std::string& src) const {
    auto dot = src.find_last_of('.');
    if (dot == std::string::npos || dot + 1 >= src.size()) {
      return false;
    }
    std::string ext = src.substr(dot + 1);
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
    return ext == "mp3" || ext == "aac" || ext == "m4a" || ext == "wav" || ext == "flac";
  }

  bool opened_ = false;
  int sample_rate_ = 48000;
  int channels_ = 2;
};

std::unique_ptr<Decoder> CreateStubDecoder() {
  return std::make_unique<DecoderStub>();
}

}  // namespace sw
