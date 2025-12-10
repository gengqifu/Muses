package com.soundwave.host

import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.ArrayAdapter
import android.widget.Spinner
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import com.google.android.material.button.MaterialButton
import com.soundwave.adapter.PcmRenderersFactory
import com.soundwave.adapter.PcmTapProcessor
import com.soundwave.core.SpectrumEngine

class MainActivity : AppCompatActivity() {

  private val tap = PcmTapProcessor()
  private val spectrum = SpectrumEngine(windowSize = 1024)
  private lateinit var player: ExoPlayer
  private val handler = Handler(Looper.getMainLooper())
  private val sampleRateGuess = 48000 // Adapter未包含采样率，这里使用常见的 48k 作为估计。
  private lateinit var assetSpinner: Spinner

  private val pollTask = object : Runnable {
    override fun run() {
      val frames = tap.drain(4)
      val dropped = tap.droppedSinceLastDrain()
      val sb = StringBuilder()
      if (dropped > 0) sb.append("dropped=").append(dropped).append("\n")
      frames.forEach { frame ->
        val spec = spectrum.compute(frame.samples, sampleRateGuess)
        spec?.let {
          // 取前三个频点粗略展示
          val top = it.take(3).joinToString(prefix = "[", postfix = "]") { v -> "%.4f".format(v) }
          sb.append("seq=").append(frame.sequence)
            .append(" bins=").append(it.size)
            .append(" top3=").append(top)
            .append("\n")
        }
      }
      if (sb.isNotEmpty()) {
        findViewById<android.widget.TextView>(R.id.logView).text = sb.toString()
        Log.d("HostSpectrum", sb.toString())
      }
      handler.postDelayed(this, 500)
    }
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)

    player = ExoPlayer.Builder(this, PcmRenderersFactory(this, tap)).build()
    assetSpinner = findViewById(R.id.assetSpinner)
    setupAssetList()

    findViewById<MaterialButton>(R.id.playButton).setOnClickListener {
      // 默认播放 assets/sample.wav，离线可用。
      val assetName = (assetSpinner.selectedItem as? String) ?: "sample_440.wav"
      val assetUri = Uri.parse("asset:///$assetName")
      player.setMediaItem(MediaItem.fromUri(assetUri))
      player.prepare()
      player.play()
      handler.post(pollTask)
      findViewById<TextView>(R.id.status).text = "Playing: $assetName"
    }

    findViewById<MaterialButton>(R.id.stopButton).setOnClickListener {
      player.pause()
      handler.removeCallbacks(pollTask)
      findViewById<TextView>(R.id.status).text = "Stopped"
    }
  }

  private fun setupAssetList() {
    val names = assets.list("")?.filter { it.endsWith(".wav") }?.sorted()
      ?: listOf("sample_440.wav")
    val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, names)
    adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    assetSpinner.adapter = adapter
  }

  override fun onDestroy() {
    super.onDestroy()
    handler.removeCallbacks(pollTask)
    player.release()
  }
}
