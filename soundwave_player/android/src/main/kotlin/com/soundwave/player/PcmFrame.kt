package com.soundwave.player

data class PcmFrame(
  val sequence: Long,
  val timestampMs: Long,
  val samples: FloatArray
)
