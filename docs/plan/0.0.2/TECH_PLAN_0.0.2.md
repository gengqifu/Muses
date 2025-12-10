# SoundWave 0.0.2 技术方案（PCM 输入 + KissFFT + 原生库发布）

## 1. 背景与目标
- 完全移除 FFmpeg，播放解码由上层应用集成平台能力（Android ExoPlayer/MediaCodec，iOS AVPlayer/AVFoundation），SDK 接收解码后的 PCM。
- 统一 FFT 实现为 KissFFT（Android/iOS 同一套参数和归一化），替换现有 Kotlin FFT 与 iOS vDSP。
- 封装 PCM 处理（波形/频谱）能力为可发布的原生库：Android 产出 AAR（支持 Maven），iOS 产出 XCFramework；核心实现放在独立原生 SDK module，Flutter 插件仅作为壳层依赖该 SDK，demo 通过插件桥接调用。
- 项目许可证切换为 Apache License 2.0，同时保留第三方依赖 LICENSE 摘录（含 KissFFT）。
- Demo 打包 `soundwave_player/example/assets/audio` 下的音频，便于开箱测试。

## 2. 范围与交付
- 核心交付
  - 数据接口：SDK 接收上层推送的 PCM（float32，多声道交错，携带采样率/通道数/时间戳），输出波形抽样与 FFT 频谱。
  - FFT：KissFFT 为唯一实现；参数统一（默认 nfft=1024，hop=512，Hann 窗，输出幅度谱归一化到 [0,1]，保留原始幅度）。
  - 数据面：PCM 输入后 downmix，再做节流输出波形帧与频谱帧。
  - API：核心聚焦初始化、参数配置、PCM 推送、波形/频谱订阅与错误回调；可选提供平台播放器适配层（对齐 ExoPlayer API）供 demo 快速集成。
  - 产物：Android AAR（Maven 可发布）、iOS XCFramework；核心封装在独立原生 SDK module，调试可直接依赖源码 module。
  - Flutter 插件：优先复用现有 MethodChannel，补充映射新 API/错误回调；作为壳层依赖原生 SDK module；Flutter demo 绘制波形/频谱，可选调用库内原生绘制示例。
  - 许可：仓库主 LICENSE 改为 Apache 2.0，新增 NOTICE/DEPENDENCIES，列出 KissFFT 等第三方许可摘录。
- 非目标（本版本不做）
  - 非平台解码器扩展（例如自建软解）。
  - 高阶编辑/导出能力，仅预留接口不实现。

## 3. 架构与实现要点
- 数据链路
  - 上层应用解码输出 PCM；SDK 提供 PCM ingress（带采样率/通道/时间戳校验）、ring buffer 与节流。
  - 可选播放适配层：Android 基于 ExoPlayer，iOS 基于 AVPlayer/AVAudioEngine，仅用于 demo/集成示例。
- FFT 与数据管线
  - C/C++ KissFFT 封装为共享模块，JNI/ObjC++ 统一接口；窗口化（Hann/Hamming 预留），归一化一致。
  - 数据流：上层解码 → PCM 推送 → ingress 校验 → 缓冲/抽样/节流 → downmix → 波形帧 + FFT 帧。
- 组件化
  - Android：`visualization-core`（名待定）Gradle module → 产出 AAR；发布到 Maven 仓库；插件依赖此 module。
  - iOS：对应核心作为静态库/动态库组合为 XCFramework；支持本地与二进制分发；插件通过桥接调用。
  - Flutter：插件层 API 映射库接口，Dart 层 CustomPainter 绘制；demo 依赖插件（发布版直接依赖二进制，调试版依赖源码）。
- 资源
  - 在 `pubspec.yaml` 中声明 `soundwave_player/example/assets/audio` 下的文件为 assets，保证打包进 demo App。

## 4. API 与数据格式
- 核心接口：`init(config)`, `pushPcmFrame(frame)`, `subscribeWaveform(...)`, `subscribeSpectrum(...)`, `unsubscribe(...)`, `setFftParams(...)`, `setThrottle(...)`。
- PCM 输入：float32，交错多声道，携带采样率/通道数/时间戳/序号，推荐帧长 1024/2048，推送频率与 hop 对齐；downmix 规则 `(L+R)/2`。
- FFT 输出：`bins[]` 幅度谱（归一化），附原始幅度；`binHz = sampleRate / nfft`；附时间戳/序号/窗口类型。
- 错误回调：输入格式异常（采样率/通道突变、帧长异常）、缓冲过载、FFT 计算错误；如使用可选播放器适配层，播放器错误需透传。
- 可选播放适配层：`load/play/pause/stop/seek` 与 ExoPlayer 语义对齐，供 demo/快速集成使用。

## 5. 工作拆解（建议顺序）
1) 移除 FFmpeg：清理 CMake/Gradle/Pod 依赖、源码与二进制；更新文档与构建脚本。
2) 数据接口落地：定义并实现 PCM ingress（格式校验、时间戳/序号、节流）；上层能推送 PCM 并拿到波形/频谱。
3) FFT 统一：接入 KissFFT（Android/iOS），删除 Kotlin FFT 与 vDSP 路径；参数/归一化一致；新增跨端对齐测试。
4) 组件化与发布：拆出核心 module，完成 AAR/XCFramework 构建脚本；准备 Maven/XCFramework 发布配置；插件依赖重定向到新 module。
5) Flutter demo 调整：demo 使用平台播放器解码并推送 PCM；插件 API 映射新接口；声明 assets；验证波形/频谱绘制。
6) 可选播放适配层：提供 ExoPlayer/AVPlayer 封装供 demo/快速接入（可选项，保持与核心解耦）。
7) 许可更新：主 LICENSE 改为 Apache 2.0，新增 NOTICE/DEPENDENCIES；检查第三方许可引用。
8) 回归与验收：跑通 `flutter analyze/test`，PCM/FFT 管线集成测试，长稳播放 smoke（demo 路径）。

## 6. 测试与验收标准
- 单测：KissFFT 频点正确性（单频/双频/白噪）、窗口与 nfft/hop 参数覆盖；PCM 序号/节流。
- 集成：上层推送 PCM（本地/HTTP 播放由上层完成），验证波形/谱同步；错误回调覆盖格式异常/缓冲过载；前后台切换恢复。
- 性能：波形/谱刷新流畅，目标 60fps；长稳播放 1–2 小时无 XRuns/明显内存增长。
- 产物验证：AAR/XCFramework 构建与本地集成验证；Flutter demo 使用发布版/源码版均可跑通。

## 7. 风险与缓解
- 输入契约不一致：明确 PCM 规格/帧长/采样率、通道变化处理；提供错误码或动态适配。
- 性能回归：在处理线程避免重计算，FFT 单独线程/节流；使用复用缓冲减少分配。
- 发布流程：提前验证 Maven/XCFramework 构建与签名；提供脚本化流程。
- 许可遗漏：脚本检查 GPL 片段，人工复核 README/构建脚本与第三方 LICENSE 摘录。

## 8. 里程碑
- M1：FFmpeg 移除 + PCM 数据接口落地（上层推送 PCM，SDK 输出波形/频谱）。
- M2：KissFFT 统一完成，跨端对齐测试通过。
- M3：核心模块拆分，AAR/XCFramework 构建与插件联调完成；demo 播放解码并推送 PCM，波形/可视化通过。
- M4：LICENSE/NOTICE 更新，发布产物验证完成，端到端回归通过。
