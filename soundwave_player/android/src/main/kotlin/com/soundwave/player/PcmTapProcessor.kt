package com.soundwave.player

import android.os.SystemClock
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.audio.AudioProcessor
import androidx.media3.exoplayer.audio.AudioProcessor.AudioFormat
import androidx.media3.exoplayer.audio.BaseAudioProcessor
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicInteger

@UnstableApi
class PcmTapProcessor : BaseAudioProcessor() {
  private val queue: ConcurrentLinkedQueue<PcmFrame> = ConcurrentLinkedQueue()
  private var sequence: Long = 0
  private var inputEnded = false
  private var lastFormat: AudioFormat? = null
  private val droppedCounter = AtomicInteger(0)
  private val maxQueueFrames = 60

  override fun onConfigure(inputAudioFormat: AudioFormat): AudioFormat? {
    if (!AudioProcessor.isEncodingLinearPcm(inputAudioFormat.encoding)) {
      throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
    }
    lastFormat = inputAudioFormat
    return inputAudioFormat
  }

  override fun queueInput(inputBuffer: ByteBuffer) {
    val remaining = inputBuffer.remaining()
    if (remaining == 0) {
      return
    }
    // Copy input to output so playback continues.
    val outBuffer = replaceOutputBuffer(remaining)
    val data = ByteArray(remaining)
    inputBuffer.get(data)
    outBuffer.put(data)
    outBuffer.flip()
    setOutputBuffer(outBuffer)

    // Convert PCM to float samples for side-channel.
    val format = lastFormat ?: return
    val samples = when (format.encoding) {
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

  override fun onQueueEndOfStream() {
    inputEnded = true
  }

  override fun isEnded(): Boolean = inputEnded

  override fun onReset() {
    queue.clear()
    sequence = 0
    inputEnded = false
    lastFormat = null
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
