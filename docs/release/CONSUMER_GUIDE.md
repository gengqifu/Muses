## SoundWave SDK 集成说明（Android/iOS，纯原生）

> 版本号示例使用 `0.0.2-local`。发布时请替换为实际版本。

### Android（AAR）
产物（来自 `scripts/publish_android_local.sh` 输出）：
```
com.soundwave.soundwave_player:core:<version>
com.soundwave.soundwave_player:adapter:<version>
com.soundwave.soundwave_player:soundwave_player:<version>   # 仅 Flutter 壳需要
```

推荐集成（纯原生宿主仅需 core + adapter）：
```gradle
repositories {
    mavenLocal()
    maven { url uri("/path/to/build/maven-repo") } // 若使用本地仓库输出
    google()
    mavenCentral()
}

dependencies {
    implementation "com.soundwave.soundwave_player:core:0.0.2-local"
    implementation "com.soundwave.soundwave_player:adapter:0.0.2-local"
    // Flutter 插件壳仅在 Flutter 项目中需要：
    // implementation "com.soundwave.soundwave_player:soundwave_player:0.0.2-local"
}
```

注：
- core AAR 内含 PCM 队列、SpectrumEngine（KissFFT）和 native JNI。
- adapter AAR 提供 ExoPlayer tap（PcmTapProcessor/PcmRenderersFactory）示例。
- 需要 Media3 依赖（已在 adapter/build.gradle 声明）。

### iOS（XCFramework）
产物（来自 `scripts/publish_ios_xcframework.sh` 输出）：
```
build/ios-dist/SoundwaveCore-<version>.zip
build/ios-dist/checksums-<version>.txt
```

集成（手工或脚本解压后引入）：
1. 解压 `SoundwaveCore-<version>.zip`，将 `SoundwaveCore.xcframework` 拖入 Xcode（Embed & Sign）。
2. 在 Swift/ObjC 代码中直接使用 `SpectrumEngine` 或 C 接口；示例见 `integration/ios-host/Sources/SpectrumHost.swift`。
3. 若需 CocoaPods：可将 `soundwave_core.podspec` 发布到内部源，并指向 xcframework 路径。

### 参考脚本
- Android 发布到本地 Maven：`scripts/publish_android_local.sh`
- iOS 打包 xcframework：`scripts/publish_ios_xcframework.sh`

### 示例宿主
- Android：`integration/android-host`（下拉选择测试音频，验证 PCM/频谱）。
- iOS：`integration/ios-host`（资源与代码示例，可直接拷贝到现有工程）。
