package com.soundwave.adapter

import android.os.SystemClock
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.exoplayer.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import com.soundwave.core.PcmFrame
import com.soundwave.core.PcmFrameBuffer
import java.nio.ByteBuffer
import java.nio.ByteOrder

@UnstableApi
class PcmTapProcessor : BaseAudioProcessor() {
  private val buffer = PcmFrameBuffer()
  private var channelCount: Int = 1

  override fun onConfigure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
    channelCount = if (inputAudioFormat.channelCount > 0) inputAudioFormat.channelCount else 1
    return inputAudioFormat
  }

  override fun queueInput(inputBuffer: ByteBuffer) {
    if (!inputBuffer.hasRemaining()) {
      return
    }

    val outBuffer = replaceOutputBuffer(inputBuffer.remaining())
    val bufferForTap = inputBuffer.duplicate().order(ByteOrder.nativeOrder())
    outBuffer.put(inputBuffer)
    outBuffer.flip()

    val remaining = bufferForTap.remaining()
    val data = ByteArray(remaining)
    bufferForTap.get(data)

    val samples = when (outputAudioFormat.encoding) {
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

    val mono = if (channelCount <= 1 || samples.isEmpty()) {
      samples
    } else {
      val frames = samples.size / channelCount
      val mixed = FloatArray(frames)
      for (i in 0 until frames) {
        var sum = 0f
        for (ch in 0 until channelCount) {
          val idx = i * channelCount + ch
          if (idx < samples.size) sum += samples[idx]
        }
        mixed[i] = sum / channelCount
      }
      mixed
    }

    buffer.push(mono, SystemClock.elapsedRealtime())
  }

  override fun onQueueEndOfStream() { }

  public override fun onReset() {
    buffer.onReset()
  }

  fun drain(maxFrames: Int): List<PcmFrame> {
    return buffer.drain(maxFrames)
  }

  fun droppedSinceLastDrain(): Int = buffer.droppedSinceLastDrain()
}
