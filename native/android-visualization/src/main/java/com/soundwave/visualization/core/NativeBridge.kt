package com.soundwave.visualization.core

/**
 * JNI 桥接占位：当前仅返回版本号，后续接入 native/core 能力。
 */
object NativeBridge {
    init {
        System.loadLibrary("visualizationcore")
    }

    external fun nativeVersion(): String
}
