#pragma once

#include <cstdint>
#include <deque>
#include <vector>

#include "audio_engine.h"
#include "pcm_throttler.h"

namespace sw {

struct PcmIngressConfig {
  int expected_sample_rate = 0;  // 0 表示不校验
  int expected_channels = 0;     // 0 表示不校验
  PcmThrottleConfig throttle;
};

struct PcmInputFrame {
  const float* data = nullptr;
  size_t num_frames = 0;
  int sample_rate = 0;
  int channels = 0;
  int64_t timestamp_ms = 0;
  uint32_t sequence = 0;
};

// 负责校验上层推送的 PCM，并按节流规则输出队列。
class PcmIngress {
 public:
  explicit PcmIngress(const PcmIngressConfig& config);

  // 推送一帧 PCM，now_ms 为当前时间（用于节流）。
  Status Push(const PcmInputFrame& frame, int64_t now_ms);

  // 取出一帧经过节流的输出；若无可用帧返回 false。
  bool Pop(PcmFrame& out);

  void Reset();

 private:
 struct OwnedFrame {
    PcmFrame frame;
  };

  PcmIngressConfig cfg_;
  PcmThrottler throttler_;
  std::deque<OwnedFrame> queue_;
};

}  // namespace sw
