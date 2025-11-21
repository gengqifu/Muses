# soundwave_player

SoundWave Flutter 插件，用于桥接移动端音频播放/可视化能力（时域波形、频谱）。当前为接口/事件流占位与契约测试骨架。

## 安装

```yaml
dependencies:
  soundwave_player:
    git: https://github.com/gengqifu/SoundWave.git
```

## 快速开始（占位实现）

```dart
import 'package:soundwave_player/soundwave_player.dart';

final player = SoundwavePlayer();

Future<void> init() async {
  await player.init(const SoundwaveConfig(sampleRate: 48000, bufferSize: 2048, channels: 2));
  await player.load('file://sample'); // 当前原生端为占位实现
  await player.play(); // 占位，后续实现原生播放
}

void listen() {
  player.stateEvents.listen((event) {
    // TODO: handle state
  });
  player.pcmEvents.listen((pcm) {
    // TODO: handle PCM frames
  });
  player.spectrumEvents.listen((spectrum) {
    // TODO: handle spectrum data
  });
}
```

### 约束与注意
- 初始化只允许一次；未 init 的调用会抛 `StateError`。
- 参数校验：空 source、负 `seek`、非正 sampleRate/bufferSize/channels 会抛 `ArgumentError`。
- 原生侧目前为占位（返回成功，无实际播放/事件），后续实现将完善。

## 开发

- 格式化：`HOME=/your/writable/home dart format lib test example/lib`
- 静态检查：`HOME=/your/writable/home flutter analyze`
- 单元测试：`HOME=/your/writable/home flutter test`

> 使用本仓库的建议 HOME（避免 lockfile 权限问题）：`/Users/gengqifu/git/ext/SoundWave/.home`
