#include "pcm_ingress.h"

#include <gtest/gtest.h>
#include <vector>

namespace sw {

TEST(PcmIngressTest, RejectsInvalidInputs) {
  PcmIngressConfig cfg;
  cfg.expected_sample_rate = 48000;
  cfg.expected_channels = 2;
  cfg.throttle.max_fps = 60;
  cfg.throttle.max_pending = 4;
  PcmIngress ingress(cfg);

  const float samples[4] = {0, 0, 0, 0};
  PcmInputFrame frame{samples, 2, 48000, 2, 0, 1};

  // Null data
  PcmInputFrame bad = frame;
  bad.data = nullptr;
  EXPECT_EQ(ingress.Push(bad, 0), Status::kInvalidArguments);

  // Zero frames
  bad = frame;
  bad.num_frames = 0;
  EXPECT_EQ(ingress.Push(bad, 0), Status::kInvalidArguments);

  // Sample rate mismatch
  bad = frame;
  bad.sample_rate = 44100;
  EXPECT_EQ(ingress.Push(bad, 0), Status::kInvalidArguments);

  // Channel mismatch
  bad = frame;
  bad.channels = 1;
  EXPECT_EQ(ingress.Push(bad, 0), Status::kInvalidArguments);
}

TEST(PcmIngressTest, ThrottleAndEnqueueFrames) {
  PcmIngressConfig cfg;
  cfg.expected_sample_rate = 48000;
  cfg.expected_channels = 2;
  cfg.throttle.max_fps = 1;       // allow 1 per second
  cfg.throttle.max_pending = 1;   // one pending before drop marker
  PcmIngress ingress(cfg);

  std::vector<float> samples(4, 1.0f);
  PcmInputFrame frame{samples.data(), 2, 48000, 2, 100, 1};

  // First frame emits immediately.
  EXPECT_EQ(ingress.Push(frame, 0), Status::kOk);
  PcmFrame out;
  ASSERT_TRUE(ingress.Pop(out));
  EXPECT_FALSE(out.dropped);
  ASSERT_TRUE(out.owner);
  EXPECT_EQ(out.owner->size(), samples.size());
  EXPECT_EQ(out.sequence, 1u);
  EXPECT_EQ(out.timestamp_ms, 100);

  // Second frame within interval is buffered (no output).
  frame.sequence = 2;
  frame.timestamp_ms = 200;
  EXPECT_EQ(ingress.Push(frame, 100), Status::kOk);
  EXPECT_FALSE(ingress.Pop(out));

  // Third frame exceeds pending -> emits drop marker.
  frame.sequence = 3;
  frame.timestamp_ms = 300;
  EXPECT_EQ(ingress.Push(frame, 200), Status::kOk);
  ASSERT_TRUE(ingress.Pop(out));
  EXPECT_TRUE(out.dropped);
  EXPECT_EQ(out.sequence, 3u);
  EXPECT_EQ(out.dropped_before, 1u);
  EXPECT_EQ(out.num_frames, 0);
}

}  // namespace sw
