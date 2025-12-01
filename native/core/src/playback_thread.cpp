#include "playback_thread.h"

#include <algorithm>
#include <chrono>
#include <vector>

namespace sw {

namespace {
constexpr int kDefaultFramesPerBuffer = 256;
}

PlaybackThread::PlaybackThread(RingBuffer& buffer, PlaybackConfig config)
    : buffer_(buffer), cfg_(config) {
  if (cfg_.frames_per_buffer <= 0) {
    cfg_.frames_per_buffer = kDefaultFramesPerBuffer;
  }
}

PlaybackThread::~PlaybackThread() { Stop(); }

bool PlaybackThread::Start() {
  if (running_.load()) {
    return false;
  }
  if (cfg_.sample_rate <= 0 || cfg_.channels <= 0 || cfg_.frames_per_buffer <= 0) {
    return false;
  }
  running_.store(true);
  thread_ = std::thread(&PlaybackThread::ThreadMain, this);
  return true;
}

void PlaybackThread::Stop() {
  running_.store(false);
  if (thread_.joinable()) {
    thread_.join();
  }
}

void PlaybackThread::SetPositionCallback(std::function<void(int64_t)> cb) {
  std::lock_guard<std::mutex> lock(cb_mu_);
  pos_cb_ = std::move(cb);
}

void PlaybackThread::ThreadMain() {
  std::vector<float> local;
  local.resize(static_cast<size_t>(cfg_.frames_per_buffer * cfg_.channels));
  const int sample_rate = cfg_.sample_rate;
  const int frames_per_buffer = cfg_.frames_per_buffer;
  auto next_deadline = std::chrono::steady_clock::now();

  while (running_.load()) {
    size_t frames = buffer_.Read(local.data(), static_cast<size_t>(frames_per_buffer));
    if (frames == 0) {
      std::this_thread::sleep_for(std::chrono::milliseconds(1));
      continue;
    }
    // Advance clock based on consumed frames to mimic real-time pacing.
    const int64_t delta_ms = static_cast<int64_t>(frames * 1000 / sample_rate);
    const auto delta_ns = std::chrono::nanoseconds(static_cast<int64_t>(
        (1000000000LL * static_cast<int64_t>(frames)) / static_cast<int64_t>(sample_rate)));
    next_deadline += delta_ns;
    int64_t now = position_ms_.fetch_add(delta_ms) + delta_ms;
    // Notify callback.
    std::function<void(int64_t)> cb_copy;
    {
      std::lock_guard<std::mutex> lock(cb_mu_);
      cb_copy = pos_cb_;
    }
    if (cb_copy) {
      cb_copy(now);
    }
    const auto sleep_for = next_deadline - std::chrono::steady_clock::now();
    if (sleep_for > std::chrono::nanoseconds::zero()) {
      std::this_thread::sleep_for(sleep_for);
    } else {
      std::this_thread::yield();
    }
  }
}

}  // namespace sw
