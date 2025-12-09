#include "pcm_ingress.h"

#include <algorithm>

namespace sw {

PcmIngress::PcmIngress(const PcmIngressConfig& config)
    : cfg_(config), throttler_(config.throttle) {}

Status PcmIngress::Push(const PcmInputFrame& in, int64_t now_ms) {
  if (in.data == nullptr || in.num_frames == 0 || in.sample_rate <= 0 || in.channels <= 0) {
    return Status::kInvalidArguments;
  }
  if (cfg_.expected_sample_rate > 0 && in.sample_rate != cfg_.expected_sample_rate) {
    return Status::kInvalidArguments;
  }
  if (cfg_.expected_channels > 0 && in.channels != cfg_.expected_channels) {
    return Status::kInvalidArguments;
  }

  PcmThrottleInput input_meta{
      in.sequence,
      in.timestamp_ms,
      static_cast<int>(in.num_frames),
      in.channels,
  };
  auto outputs = throttler_.Push(input_meta, now_ms);
  if (outputs.empty()) {
    return Status::kOk;
  }

  for (const auto& out : outputs) {
    OwnedFrame owned;
    owned.frame.sequence = out.sequence;
    owned.frame.timestamp_ms = out.timestamp_ms;
    owned.frame.dropped_before = out.dropped_before;
    owned.frame.dropped = out.dropped;
    owned.frame.sample_rate = in.sample_rate;
    owned.frame.num_channels = in.channels;
    owned.frame.num_frames = static_cast<int>(in.num_frames);

    if (!out.dropped) {
      const size_t samples = in.num_frames * static_cast<size_t>(in.channels);
      auto buffer = std::make_shared<std::vector<float>>();
      buffer->resize(samples);
      std::copy(in.data, in.data + samples, buffer->begin());
      owned.frame.owner = buffer;
      owned.frame.data = buffer->data();
    } else {
      owned.frame.data = nullptr;
      owned.frame.num_frames = 0;
      owned.frame.owner.reset();
    }
    queue_.push_back(std::move(owned));
  }

  return Status::kOk;
}

bool PcmIngress::Pop(PcmFrame& out) {
  if (queue_.empty()) return false;
  OwnedFrame& front = queue_.front();
  out = front.frame;
  queue_.pop_front();
  return true;
}

void PcmIngress::Reset() {
  queue_.clear();
  throttler_.Reset();
}

}  // namespace sw
