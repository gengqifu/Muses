#include "pcm_throttler.h"

namespace sw {

PcmThrottler::PcmThrottler(const PcmThrottleConfig& config) : config_(config) {}

std::vector<PcmThrottleOutput> PcmThrottler::Push(const PcmThrottleInput& input, int64_t now_ms) {
  std::vector<PcmThrottleOutput> out;

  const int min_interval_ms =
      config_.max_fps > 0 ? static_cast<int>(1000 / config_.max_fps) : 0;

  const bool should_emit =
      last_emit_ms_ < 0 || min_interval_ms <= 0 ||
      (now_ms - last_emit_ms_) >= min_interval_ms;

  if (should_emit) {
    out.push_back(PcmThrottleOutput{
        input.sequence,
        input.timestamp_ms,
        pending_drops_,
        /*dropped=*/false,
    });
    pending_drops_ = 0;
    last_emit_ms_ = now_ms;
  } else {
    // 抽稀当前帧并累计丢弃数，超过 max_pending 也继续累计，避免丢失统计。
    pending_drops_++;
  }

  return out;
}

void PcmThrottler::Reset() {
  last_emit_ms_ = -1;
  pending_drops_ = 0;
}

}  // namespace sw
