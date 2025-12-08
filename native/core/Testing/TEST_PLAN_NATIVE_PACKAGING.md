# Native Packaging Test Plan (Story 08)

目标：验证“纯原生可发布包”在 Android/iOS 上的核心能力（PCM/FFT/节流/导出）与平台桥接（JNI/ObjC），确保可被上层 Demo/插件复用且无 Flutter 依赖。

## 测试层次
- C++ Core（现有 gtest，可复用/补充）
  - ring buffer / playback thread / pcm throttler / fft spectrum。
  - 导出：WAV/CSV/JSON 写入与元数据（待补）。
- 平台桥接
  - Android JNI：函数签名/类型映射，错误码/异常映射，生命周期（init/load/play/pause/stop/seek），PCM/谱回调节流正确性，导出开关。
  - iOS ObjC/Swift：同上，验证 vDSP/KissFFT 双实现切换，线程安全（主/后台）。
- 集成与产物
  - AAR（本地 m2 / 内测仓库）集成验收：可被简单原生 app 引入，JNI 调用通过，CPU/内存无泄漏。
  - XCFramework + Pod/SPM 验收：`pod lib lint` / `swift package diagnose` 通过，示例 app 可播放并回调波形/谱。

## 用例清单（优先级）
- 核心
  - FFT 结果一致性：实数输入 vs 参考，DC/Nyquist 处理；双实现（KissFFT/vDSP）对齐。
  - PCM 节流：限频/限帧，丢弃计数上报。
  - WAV/CSV/JSON 导出：头信息、序列/时间戳/binHz，对比输入帧 bit-exact。
- JNI 桥接
  - 类型映射：`float[]`/`double[]`/`byte[]` 输入输出不截断；`jlong` 时间戳正确。
  - 生命周期：多次 init/load/stop 不崩溃；错误码到 Java 异常/返回值映射。
  - 回调频率：高频 PCM/谱事件下节流仍生效，无 ANR。
  - 异常路径：空源、非法采样率、IO 错误触发预期错误码。
- iOS 桥接
  - Swift/ObjC API 可用，线程切换安全（主线程监听/后台推流）。
  - FFT 后端切换：vDSP 默认，KissFFT 备用，结果对齐。
  - 导出：文件写入与回调并行不阻塞 UI 线程。
- 集成烟测
  - Android：基于 AAR 的最小原生 app 播放 + 波形/谱回调 + 导出文件校验。
  - iOS：基于 XCFramework 的最小 app 播放 + 回调 + 导出校验。

## 执行方式
- CMake/gtest（现有 `native/core`）继续使用，补充导出/FFT 对齐用例；新增 JNI/ObjC 桥接测试可单独目标（如 `jni_bridge_tests`/`objc_bridge_tests`），仅在对应工具链可用时构建。
- 集成验收脚本：在 Story 08 发布脚本中增加 `android aar assemble + jni smoke` / `ios xcframework + objc smoke` 步骤，输出日志供 CI。
