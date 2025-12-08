# Changelog (draft)

## [Unreleased]
- 流式播放：Story10 暂缓，相关测试已跳过或允许失败。

## [0.0.2] - 2025-12-08
- 移除 FFmpeg 依赖与源码：删除 `ffmpeg/` 目录与编译脚本，CMake 仅保留平台解码桩与可视化核心。
- 门禁回归：`flutter analyze`、`flutter test`、Android/iOS 构建通过；native gtest 在禁用 FFmpeg 配置下通过。
- 集成冒烟：Android 平台解码集成测试产生 PCM 帧通过（iOS 待补）。
- 文档更新：README/AGENTS/DESIGN/PRD 等改为平台解码方案。

## [0.0.1] - 2025-12-04
- 本地播放 + 实时波形/频谱 Demo 跑通，支持 iOS/Android（Flutter 插件 + 示例）。
- 频谱绘制：新增对数频率轴采样与幅度插值，低频分布更均衡；默认线性幅度，避免噪声假峰；黄金用例覆盖正弦/方波/锯齿/噪声/扫频。
- 可视化校验：示例内置测试音频（sine/square/saw/白噪/粉噪/扫频/静音），README 补充手工验证与 ffmpeg 生成命令。
- Android/iOS PCM 采集：Android Tap 下混多声道再 FFT；iOS PCM tap 定时器稳定性修复。
- 文档：完善概要设计（架构/时序/交互图）、协作复盘、README 更新。
