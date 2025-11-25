import 'dart:async';

import 'soundwave_config.dart';
import 'audio_state.dart';
import 'soundwave_player.dart';

/// Dart 层控制器占位实现：封装 SoundwavePlayer，管理状态流。
class AudioController {
  AudioController({SoundwavePlayer? platform})
      : _platform = platform ?? SoundwavePlayer();

  final SoundwavePlayer _platform;

  /// 状态流（后续实现）。
  Stream<AudioState> get states => _stateController.stream;

  final StreamController<AudioState> _stateController =
      StreamController<AudioState>.broadcast();

  AudioState _state = AudioState.initial();
  AudioState get state => _state;

  Future<void> init(SoundwaveConfig config) {
    // TODO: 实现初始化和状态订阅
    throw UnimplementedError();
  }

  Future<void> load(String source, {Map<String, Object?>? headers}) {
    // TODO: 调用平台 load 并处理错误
    throw UnimplementedError();
  }

  Future<void> play() {
    // TODO: 调用平台 play 并更新状态
    throw UnimplementedError();
  }

  Future<void> pause() {
    // TODO: 调用平台 pause 并更新状态
    throw UnimplementedError();
  }

  Future<void> stop() {
    // TODO: 调用平台 stop 并更新状态
    throw UnimplementedError();
  }

  Future<void> seek(Duration position) {
    // TODO: 调用平台 seek 并更新状态
    throw UnimplementedError();
  }

  void dispose() {
    _stateController.close();
  }
}
