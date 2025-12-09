package com.soundwave.visualization.core

/**
 * 占位 API：后续将挂接 JNI 到 native/core (PCM/FFT/导出)。
 */
object VisualizationCore {
    const val VERSION = "0.0.2-native-SNAPSHOT"

    /**
     * 当前仅返回 native 占位版本号，验证 JNI/NDK 依赖链。
     */
    @JvmStatic
    fun nativeVersion(): String = NativeBridge.nativeVersion()
}
