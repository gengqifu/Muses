# 回归用例：前后台与播放控制

适用范围：Android/iOS 原生 Host demo、Flutter example（依赖平台播放器）。验证 play/pause/stop/seek、前后台切换、PCM/频谱事件恢复。

## 共用资源
- 资产音频：`sample.wav`、`sample.mp3`、`sweep_20_20k.wav`、`silence.wav`。
- 目标：播放期间波形/频谱连续输出；seek 后事件时间/序号无明显跳变；前后台切换恢复播放与事件。

## Android Host（integration/android-host）
1) 启动 app，选择 `sample.wav`，点击播放：波形/频谱实时更新，时间/进度同步。
2) 点击暂停 → 进度停止增长，波形/频谱停止刷新；再点击播放恢复。
3) 拖动 SeekBar 至 50% → 音频跳转，时间显示正确，波形/频谱继续更新。
4) 点击停止 → 进度归零，波形/频谱清空；再播放 `sweep_20_20k.wav`，低→高频谱平滑变化。
5) 前后台：播放中按 Home 后 3 秒，返回前台，播放继续或手动恢复，事件连续（无崩溃）。

## iOS Host（integration/ios-host/host）
1) 选择 `sample.wav`，点播放：波形/频谱实时刷新，时间/进度同步。
2) 点暂停 → 进度停，波形/频谱停止刷新；再播放恢复。
3) 拖动滑杆到 50% → 时间/进度跳转，波形/频谱继续刷新。
4) 停止 → 进度归零、波形/频谱清空；切换 `sweep_20_20k.wav` 验证频谱低→高平滑。
5) 前后台：播放中按 Home/锁屏后返回，播放恢复或手动恢复，事件连续（无崩溃）。

## Flutter example（soundwave_player/example）
1) `flutter run`，点击 `Use bundled sample.mp3` → Init → Load → Play，波形/频谱刷新，时间同步。
2) Pause/Resume/Stop 按钮验证状态、进度与事件同步。
3) Seek（拖动进度条）→ 时间与波形/频谱同步跳转。
4) 前后台：播放中切后台 3 秒再回到前台，播放继续或恢复，事件不中断。

## 预期与记录
- 所有用例无崩溃/无异常日志。
- 波形/频谱在播放、暂停、停止、seek 后行为与时间显示一致。
- 前后台切换后无需重启 app，音频输出与事件恢复正常。
