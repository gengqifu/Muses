package com.soundwave.player

import android.os.SystemClock
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicInteger

@UnstableApi
class PcmTapProcessor : AudioProcessor {
  private val queue: ConcurrentLinkedQueue<PcmFrame> = ConcurrentLinkedQueue()
  private var sequence: Long = 0
  private var lastFormat: AudioProcessor.AudioFormat = AudioProcessor.AudioFormat.NOT_SET
  private val droppedCounter = AtomicInteger(0)
  private val maxQueueFrames = 60
  private var inputEnded = false

  override fun configure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
    if (!Util.isEncodingLinearPcm(inputAudioFormat.encoding)) {
      throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
    }
    lastFormat = inputAudioFormat
    return inputAudioFormat
  }

  override fun isActive(): Boolean = lastFormat.encoding != C.ENCODING_INVALID

  override fun queueInput(inputBuffer: ByteBuffer) {
    val remaining = inputBuffer.remaining()
    if (remaining == 0 || lastFormat.encoding == C.ENCODING_INVALID) {
      return
    }

    // Convert PCM to float samples for side-channel.
    val data = ByteArray(remaining)
    inputBuffer.get(data)
    inputBuffer.position(inputBuffer.position() + remaining) // Manually advance position

    val samples = when (lastFormat.encoding) {
      C.ENCODING_PCM_16BIT -> {
        val bb = ByteBuffer.wrap(data).order(ByteOrder.nativeOrder())
        val arr = FloatArray(data.size / 2)
        var i = 0
        while (bb.hasRemaining()) {
          arr[i++] = bb.short.toFloat() / Short.MAX_VALUE
        }
        arr
      }
      C.ENCODING_PCM_FLOAT -> {
        val bb = ByteBuffer.wrap(data).order(ByteOrder.nativeOrder())
        val arr = FloatArray(data.size / 4)
        var i = 0
        while (bb.hasRemaining()) {
          arr[i++] = bb.float
        }
        arr
      }
      else -> FloatArray(0)
    }
    if (queue.size >= maxQueueFrames) {
      // Drop the oldest frame when over capacity.
      queue.poll()
      droppedCounter.incrementAndGet()
    }
    queue.add(PcmFrame(sequence++, SystemClock.elapsedRealtime(), samples))
  }

  override fun getOutput(): ByteBuffer = AudioProcessor.EMPTY_BUFFER

  override fun queueEndOfStream() {
    inputEnded = true
  }

  override fun isEnded(): Boolean = inputEnded

  override fun flush() {
    // No-op
  }

  public override fun reset() {
    queue.clear()
    sequence = 0
    inputEnded = false
    lastFormat = AudioProcessor.AudioFormat.NOT_SET
    droppedCounter.set(0)
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
}
