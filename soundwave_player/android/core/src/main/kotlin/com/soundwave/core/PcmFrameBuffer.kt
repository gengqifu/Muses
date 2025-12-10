package com.soundwave.core

import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * 无平台依赖的 PCM 队列，负责丢帧统计与顺序编号。
 */
class PcmFrameBuffer(
  private val maxQueueFrames: Int = 60
) {
  private val queue: ConcurrentLinkedQueue<PcmFrame> = ConcurrentLinkedQueue()
  private val sequence = AtomicLong(0)
  private val droppedCounter = AtomicInteger(0)

  fun push(samples: FloatArray, timestampMs: Long) {
    if (samples.isEmpty()) return
    if (queue.size >= maxQueueFrames) {
      queue.poll()
      droppedCounter.incrementAndGet()
    }
    queue.add(PcmFrame(sequence.getAndIncrement(), timestampMs, samples))
  }

  fun drain(maxFrames: Int): List<PcmFrame> {
    if (maxFrames <= 0) return emptyList()
    val out = mutableListOf<PcmFrame>()
    repeat(maxFrames) {
      val f = queue.poll() ?: return@repeat
      out.add(f)
    }
    return out
  }

  fun droppedSinceLastDrain(): Int = droppedCounter.getAndSet(0)

  fun onReset() {
    queue.clear()
    sequence.set(0)
    droppedCounter.set(0)
  }
}
