# SoundWave PRD 0.0.2（PCM 输入 + KissFFT 原生可视化库）

## 1. 背景与目标
- 摆脱 FFmpeg 依赖，播放解码由上层应用自行集成平台能力（Android ExoPlayer / iOS AVPlayer/AVFoundation），SDK 接受解码后的 PCM。
- 统一使用 KissFFT 完成本地 PCM → FFT 处理，提供跨平台一致的可视化能力。
- 将 PCM 处理与可视化能力封装为可发布的原生库（Android AAR/Maven，iOS XCFramework），Flutter demo 通过插件桥接调用。
- 更换项目许可证为 Apache License 2.0，保留第三方依赖（如 KissFFT）LICENSE 摘录。

## 2. 目标用户与场景
- 目标用户：音频创作/调试用户、播客/配音创作者、研发测试人员。
- 场景：
  - 在移动端加载本地/流式音频，实时查看波形与频谱。
  - 通过 demo 快速验证播放、seek、错误处理和可视化表现（demo 负责播放，SDK 负责处理与回调）。
  - 集成方可直接依赖发布的库产物（AAR/XCFramework）或源码 module。

## 3. 成功度量（KPI）
- 播放端到端延迟 < 120 ms（硬件允许前提），可视化展示延迟 < 200 ms。
- 渲染帧率目标 60 fps（性能不足可降级至 30 fps）。
- AAR/XCFramework 可独立集成，公开 API 与文档齐全；Flutter demo 正常播放与可视化。
- 长时间播放稳定：2 小时无明显 XRuns/卡顿，内存增长 < 5%。

## 4. 范围与交付
- 核心交付
  - 数据接口：SDK 接收上层解码后的 PCM（float32，多声道交错，含采样率/通道数/时间戳），输出波形抽样与 FFT 频谱。
  - 原生可视化库：统一 KissFFT；封装 PCM 抽样与 FFT 输出，提供原生绘制示例。
  - 库产物：Android 产出 AAR（支持发布 Maven），iOS 产出 XCFramework；同时保留源码 module 供调试。
  - Flutter 接入：demo 复用现有插件桥接，必要时扩展 MethodChannel API；Flutter 侧绘制波形/频谱，可选择使用库内原生绘制示例。
  - 播放控制：上层应用负责播放（ExoPlayer/AVPlayer），SDK 可提供可选适配层以对齐 play/pause/stop/seek API 供 demo/集成使用。
  - 错误回调：库暴露错误码/错误信息回调给上层（输入格式错误、缓冲过载、FFT 计算异常等）。
  - 资源打包：demo 在 `pubspec.yaml` 中直接声明 `soundwave_player/example/assets/audio` 下的音频为 assets 并打包进 App。
  - 许可证：仓库切换为 Apache 2.0，并附带第三方 LICENSE/NOTICE 摘录（含 KissFFT）。
- 非目标（本版本不做）
  - 非平台解码器扩展（如外部硬件解码）。
  - 高阶编辑能力（标注、片段导出）仅规划不实现。

## 5. 用户流程（简述）
- 打开 demo → 选择内置音频（已打包 assets）或输入 URL → demo 使用平台播放器解码并推送 PCM → SDK 输出波形/频谱 → 实时显示。
- 可执行 play/pause/stop/seek（由 demo 持有播放器实现）；发生错误时弹出/展示错误信息。
- 集成方可在自身 App 中接入 AAR/XCFramework，按同样 API 调用并订阅错误回调。

## 6. 功能需求
- 播放与控制（上层承担）
  - 上层（demo/业务 App）集成平台播放器，支持 play/pause/stop/seek；seek 完成后再向 SDK 推送 PCM。
  - SDK 可提供可选适配层封装平台播放器，保持与 ExoPlayer API 语义对齐，便于快速集成。
- 数据接口
  - 输入：上层推送解码后的 PCM 帧（float32，交错多声道），携带采样率/通道数/时间戳；可约定帧长（如 1024/2048）便于缓冲。
  - 输出：SDK 回调波形抽样与 FFT 频谱（幅度谱归一化 0..1，附原始幅度），带 `binHz`、窗口类型、序号/时间戳。
  - 节流：支持按窗口/hop 限速，防止上层无限速推送压垮处理线程。
- 可视化（波形/频谱）
  - 时域：分帧 PCM 抽样（支持抽稀限速），提供原生绘制接口/示例。
  - 频域：KissFFT，默认窗口 1024 点、hop 512、Hann 窗；输出幅度谱（0..1 归一化），可提供原始幅度值便于自定义。
  - 数据回调节流，避免压垮 UI。
- API 与回调
  - SDK 核心 API 聚焦初始化、参数配置、PCM 推送、波形/频谱订阅/取消订阅；可选播放适配层对齐 ExoPlayer 语义。
  - 错误回调：错误码 + 文本描述；输入格式异常、缓冲过载、FFT 计算错误均需上报；若使用可选播放器适配层，播放器错误也需透传。
  - Flutter 插件映射上述 API 与错误回调，保持向后兼容（必要时新增 method）。
- 打包与分发
  - Android：可生成 AAR，支持发布到 Maven；调试态 Flutter 直接依赖本地 module。
  - iOS：生成 XCFramework，支持本地集成与二进制分发。
  - 文档：提供接入说明、API 列表、错误码表、示例代码。
- 许可
  - 仓库主 LICENSE 改为 Apache 2.0；附上 KissFFT 等第三方 LICENSE 摘录与 NOTICE。

## 7. 非功能需求
- 兼容性：Android API 23+，iOS 8.0+。
- 性能：低延迟、低抖动；频谱/波形刷新流畅。
- 可测试性：播放器 API、错误回调、FFT 结果与绘制抽样可单测/集成测；发布产物可用性测试。
- 监控与日志：基础错误日志、关键性能指标预留采集点。

## 8. 技术与实现约束
- UI：Flutter demo 绘制波形/频谱，可调用库内原生绘制示例或自绘。
- 插件：优先复用现有 MethodChannel，扩展满足新 API/回调。
- 原生核心：KissFFT + 数据管线；C/C++ 为主，Android 侧 Kotlin+JNI+C++，iOS 侧 Swift+Objective-C++/C++；播放解码由上层或可选适配层处理。
- 构建：CMake 管理原生核心；Android Gradle 产出 AAR，iOS Xcode/CMake 产出 XCFramework；支持发布与本地调试双形态。

## 9. 依赖与外部接口
- Android：可选 ExoPlayer（仅用于 demo 或适配层）。
- iOS：可选 AVFoundation/AVPlayer/AVAudioEngine（仅用于 demo 或适配层）。
- FFT：KissFFT（含 LICENSE 摘录）。
- 系统能力：文件访问、网络请求、音频输出、前后台生命周期。

-## 10. 风险与缓解
+ 输入契约不一致：明确 PCM 规格与帧长约定，对采样率/通道变化提供错误码或动态适配。
+ 平台解码差异（在可选适配层中）：对采样率/通道差异做适配，增加错误码覆盖。
- AAR/XCFramework 发布流程：提前验证构建脚本与 CI；提供本地/远端仓库发布指引。
- 性能与延迟：对回调节流、复用缓冲，避免在音频回调做重计算；FFT 可单独线程。
- 兼容性：API 23+ / iOS 8+ 需验证旧设备表现，准备降级策略（降帧率/抽稀）。

## 11. 里程碑与验收要点
- M1：移除 FFmpeg，数据接口定义与 PCM 输入通路打通；验收：上层解码 PCM 可成功推送并获得波形/频谱。
- M2：KissFFT 集成，PCM 波形/频谱数据输出；验收：频谱/波形刷新流畅，参数可配置。
- M3：AAR/XCFramework 打包与 Flutter 插件联调；验收：demo 使用平台播放器解码并通过插件推送 PCM，资产音频可直接播放并可视化。
- M4：发布与许可证更新；验收：LICENSE/NOTICE 更新，发布产物可在新项目直接集成。
