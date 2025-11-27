#include "pcm_throttler.h"

namespace sw {

PcmThrottler::PcmThrottler(const PcmThrottleConfig& config) : config_(config) {}

std::vector<PcmThrottleOutput> PcmThrottler::Push(const PcmThrottleInput& input, int64_t now_ms) {
  (void)input;
  (void)now_ms;
  // TODO: 实现限频与抽稀逻辑。
  return {};
}

void PcmThrottler::Reset() {
  last_emit_ms_ = -1;
  pending_drops_ = 0;
}

}  // namespace sw
