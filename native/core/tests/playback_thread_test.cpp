#include "playback_thread.h"
#include "ring_buffer.h"

#include <gtest/gtest.h>

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <thread>
#include <vector>

using namespace std::chrono_literals;

namespace sw {

TEST(PlaybackThreadTest, PositionIsMonotonicWithProducer) {
  RingBuffer buffer(4096, 2);
  PlaybackConfig cfg;
  cfg.sample_rate = 44100;
  cfg.channels = 2;
  cfg.frames_per_buffer = 128;
  PlaybackThread playback(buffer, cfg);

  std::atomic<int64_t> last{-1};
  std::atomic<int> cb_count{0};
  std::atomic<int> regressions{0};
  std::mutex mu;
  std::condition_variable cv;

  playback.SetPositionCallback([&](int64_t pos_ms) {
    int64_t prev = last.exchange(pos_ms);
    if (prev > pos_ms) {
      regressions.fetch_add(1);
    }
    cb_count.fetch_add(1);
    cv.notify_one();
  });

  std::atomic<bool> producing{true};
  std::thread producer([&]() {
    std::vector<float> data(static_cast<size_t>(cfg.frames_per_buffer * cfg.channels), 0.0f);
    while (producing.load()) {
      size_t wrote = buffer.Write(data.data(), static_cast<size_t>(cfg.frames_per_buffer));
      if (wrote == 0) {
        std::this_thread::yield();
      }
    }
  });

  ASSERT_TRUE(playback.Start());

  {
    std::unique_lock<std::mutex> lock(mu);
    cv.wait_for(lock, 2s, [&] { return cb_count.load() >= 5; });
  }

  playback.Stop();
  producing.store(false);
  producer.join();

  EXPECT_GT(cb_count.load(), 0);
  EXPECT_EQ(regressions.load(), 0);
  EXPECT_GE(playback.position_ms(), 0);
}

TEST(PlaybackThreadTest, StopsCleanlyWithoutData) {
  RingBuffer buffer(256, 1);
  PlaybackConfig cfg;
  cfg.sample_rate = 44100;
  cfg.channels = 1;
  cfg.frames_per_buffer = 64;
  PlaybackThread playback(buffer, cfg);

  ASSERT_TRUE(playback.Start());
  std::this_thread::sleep_for(10ms);
  EXPECT_TRUE(playback.running());
  playback.Stop();
  EXPECT_FALSE(playback.running());
}

}  // namespace sw
