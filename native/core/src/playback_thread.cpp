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

  while (running_.load()) {
    size_t frames = buffer_.Read(local.data(), static_cast<size_t>(frames_per_buffer));
    if (frames == 0) {
      std::this_thread::sleep_for(std::chrono::milliseconds(1));
      continue;
    }
    // Advance clock.
    int64_t delta_ms = static_cast<int64_t>(frames * 1000 / sample_rate);
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
  }
}

}  // namespace sw
