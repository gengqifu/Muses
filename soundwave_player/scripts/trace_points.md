# 性能采样点与指标

当前聚焦本地播放链路；流式场景待 Story10 恢复。

## 采样点
- 解码→环形缓冲写入：记录帧数/耗时，计算 decode->buffer 延迟。
- 回放线程（PlaybackThread/ExoPlayer/AVPlayer）拉取→回调：记录 position_ms，计算 buffer->playback 延迟。
- PCM 推送至 Dart：记录 timestamp_ms，检查单调与回放时钟差值。
- UI 绘制：Flutter DevTools Skia trace，统计 Waveform/Spectrum 的每帧耗时与 FPS。
- 资源：CPU/内存（DevTools timeline，Android Studio profiler，Xcode Instruments）。

## 指标
- 端到端显示延迟：解码 → UI 绘制（ms）。
- 波形/频谱 FPS：目标 60，低端设备可≥30。
- CPU：播放时主线程占用 < 20%（参考），UI 线程无明显掉帧。
- 内存：长时间播放增长 < 5%，无未释放缓存。

## 工具/脚本
- `scripts/profile_local_playback.sh`：Flutter profile trace。
- `scripts/long_run_smoke.sh`：长时间播放稳定性。
- 建议开启 Flutter DevTools timeline + Skia trace；Android 可用 `systrace`/`perfetto`，iOS 用 Instruments Time Profiler。

## 记录方式
- 将 trace/日志导出到 `profile/` 目录，命名含日期/场景。
- 手动运行脚本后记录关键指标到 Story12 文档或独立报告。
