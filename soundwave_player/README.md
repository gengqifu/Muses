# soundwave_player

SoundWave Flutter 插件，用于桥接移动端音频播放/可视化能力（时域波形、频谱）。当前支持本地播放可视化（Story09/11），流式播放待 Story10 恢复。

## 安装

```yaml
dependencies:
  soundwave_player:
    git: https://github.com/gengqifu/SoundWave.git
```

## 快速开始（本地播放）

```dart
import 'package:soundwave_player/soundwave_player.dart';

final player = SoundwavePlayer();

Future<void> init() async {
  await player.init(const SoundwaveConfig(sampleRate: 44100, bufferSize: 2048, channels: 2));
  await player.load('file:///tmp/sample.mp3');
  await player.play();
}

void listen() {
  player.stateEvents.listen((event) {
    // 处理播放/缓冲/错误事件
  });
  player.pcmEvents.listen((pcm) {
    // 处理可视化 PCM 帧
  });
  player.spectrumEvents.listen((spectrum) {
    // 处理频谱数据
  });
}
```

### 约束与注意
- 初始化只允许一次；未 init 的调用会抛 `StateError`。
- 参数校验：空 source、负 `seek`、非正 sampleRate/bufferSize/channels 会抛 `ArgumentError`。
- 流式播放/弱网策略尚未实现（Story10 暂缓），当前聚焦本地播放。

### 可视化样式
```dart
const SpectrumStyle(
  barColor: Colors.cyan,
  background: Colors.black,
  barWidth: 2,
  spacing: 1,
  logScale: true,      // 幅度对数压缩，防止峰值淹没细节
  freqLogScale: true,  // 频率轴对数分布，低频更宽
);
```
- 低频占比过大时，可将 `freqLogScale` 设为 `false` 变为线性频率轴，或调小 `logScale` 影响。

## 手工验证可视化（建议流程）
1) 准备测试音频（单声道 48 kHz，避免压缩失真，可用 ffmpeg 生成）：正弦 1 kHz、方波/锯齿、白噪声/粉噪、20–20k 线性扫频、静音。  
2) 在示例页输入本地路径或使用“Use bundled …”/手动选择文件 → `Init` → `Load` → `Play`。  
3) 观察 Waveform：正弦平滑、方波平顶、噪声随机无溢出、扫频振幅/频率随时间变。  
4) 观察 Spectrum：正弦单峰；方波/锯齿多谐波递减；白噪声谱趋近平坦、粉噪高频衰减；扫频主峰随时间从低频平滑移动到高频；静音无显著能量。  
5) 如谱偏左/右，可切换 `SpectrumStyle(freqLogScale: false)` 看线性频率轴；多声道源若下混，谱为平均。  
6) 更严格可录屏/截屏，与离线工具（Python/ffmpeg 绘制的谱）对比峰值位置和形状，容忍窗函数带来的主瓣宽度与旁瓣。

### ffmpeg 生成测试音频示例（单声道 44.1 kHz，Hann + 2/(N*E_window) 归一化验证）
```bash
# 正弦 1 kHz，1s
ffmpeg -f lavfi -i "sine=frequency=1000:sample_rate=44100:duration=1" sine_1k.wav
# 方波 1 kHz（使用 sgn），1s
ffmpeg -f lavfi -i "aevalsrc=exprs=sgn(sin(2*PI*1000*t)):s=44100:d=1" square_1k.wav
# 锯齿波 1 kHz，1s
ffmpeg -f lavfi -i "aevalsrc=exprs=2*(t*1000-floor(t*1000))-1:s=44100:d=1" saw_1k.wav
# 白噪声/粉噪，1s
ffmpeg -f lavfi -i "anoisesrc=color=white:amplitude=0.5:d=1:s=44100" noise_white.wav
ffmpeg -f lavfi -i "anoisesrc=color=pink:amplitude=0.5:d=1:s=44100" noise_pink.wav
# 线性扫频 20Hz->20kHz，5s（手写公式，兼容旧 ffmpeg）
ffmpeg -f lavfi -i "aevalsrc=exprs=sin(2*PI*(20*t + 0.5*((20000-20)/5)*t*t)):s=44100:d=5" sweep_20_20k.wav
# 静音，1s
ffmpeg -f lavfi -i "anullsrc=cl=mono:r=44100:d=1" silence.wav
```

## 开发

- 格式化：`HOME=/your/writable/home dart format lib test example/lib`
- 静态检查：`HOME=/your/writable/home flutter analyze`
- 单元测试：`HOME=/your/writable/home flutter test`
- Android JNI/KissFFT：Gradle 构建自动编译 `soundwave_fft`，KissFFT 源码在 `android/src/main/cpp/kissfft`，回退路径为 Kotlin 版 FFT。

## Demo

- 验收清单：见 `docs/demo_acceptance.md`（本地播放、波形/频谱刷新、前后台切换）。
- 自动化冒烟占位：`example/integration_test/demo_smoke_test.dart`（待 UI 实现后补充）。

## 平台配置（前后台/后台播放）

- iOS：宿主 App 需在 Xcode 中开启 Background Modes（Audio），`Info.plist` 增加 `UIBackgroundModes = audio`。插件已配置 `AVAudioSessionCategoryPlayback` 并监听中断/路由变更，后台播放权限需由宿主工程启用。
- iOS 隐私：`ios/Resources/PrivacyInfo.xcprivacy` 已声明音频数据访问及必要 API 访问（时间戳、UserDefaults），如有自定义用途请补充。
- Android：目前未启用通知栏/前台 Service，如需后台播放请在宿主应用添加前台 Service 与通知渠道，并配置 `android.permission.FOREGROUND_SERVICE`/`INTERNET`；FFT 由 JNI KissFFT 完成，默认输出 44.1kHz/float32 立体声，频谱归一化与 iOS 对齐。

> 使用本仓库的建议 HOME（避免 lockfile 权限问题）：`/Users/gengqifu/git/ext/SoundWave/.home`
