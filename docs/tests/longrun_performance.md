# 长稳与性能回归指南

目标：验证连续播放 ≥60min 的稳定性（无崩溃/XRun/明显内存增长），记录 CPU/内存/帧率基线，并确保波形/频谱事件不中断。

## Flutter 示例（soundwave_player/example）
1) 构建/运行 release（连接目标设备）：  
   ```bash
   cd soundwave_player/example
   flutter run --release -d <device_id> --dart-define=SOUNDWAVE_SAMPLE_URL=file:///sdcard/Music/sample.wav
   ```  
   或使用现有脚本：`soundwave_player/scripts/long_run_smoke.sh`（默认 120min）。
2) 播放内置/指定 URL，持续 ≥60min。
3) 观测：`flutter logs` 或 `adb logcat` 中无崩溃/错误；波形/频谱持续刷新。
4) 记录资源：Android Studio Profiler / Xcode Instruments（CPU/内存）截屏或导出 trace。

## Android 原生 Host（integration/android-host）
1) 安装调试或 release 包，选择 assets 音频（如 `sample.wav`）。
2) 播放并保持前后台各 30min：先前台 30min，切后台 5min，回前台继续 30min。
3) 通过 `adb logcat` 监控是否有 ANR/崩溃；使用 Profiler 记录 CPU/内存峰值；观察波形/频谱持续刷新。
4) 如需自动化：可用 `adb shell input keyevent` 模拟 Home/Resume，计时 60min。

## iOS 原生 Host（integration/ios-host/host）
1) Xcode 运行到真机，选择 assets 音频播放。
2) 前台播放 30min，按 Home/锁屏 5min，再回前台继续 30min。
3) 通过 Xcode Memory/CPU gauge 或 Instruments (Time Profiler/Allocations) 采样，确认无异常增长；波形/频谱持续刷新。
4) 检查控制台无 AVAudioEngine 错误/崩溃。

## 验收记录模版
- 设备/OS/构建类型：  
- 音频：  
- 播放总时长：  
- 前后台切换次数：  
- CPU 峰值 / 平均：  
- 内存峰值 / 增长：  
- 波形/频谱是否中断：  
- 错误/崩溃：  
- 结论：通过/需修复
