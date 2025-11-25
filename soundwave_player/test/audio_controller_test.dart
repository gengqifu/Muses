import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave_player/soundwave_player.dart';

class FakePlatform extends SoundwavePlayer {
  FakePlatform({this.shouldThrow = false}) : super();

  bool shouldThrow;
  final StreamController<Map<String, Object?>> _stateController =
      StreamController<Map<String, Object?>>.broadcast();

  List<String> calls = [];

  @override
  Future<void> init(SoundwaveConfig config) async {
    calls.add('init');
    if (shouldThrow) throw StateError('init failed');
  }

  @override
  Future<void> load(String source, {Map<String, Object?>? headers}) async {
    calls.add('load');
    if (shouldThrow) throw StateError('load failed');
  }

  @override
  Future<void> play() async {
    calls.add('play');
    if (shouldThrow) throw StateError('play failed');
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    if (shouldThrow) throw StateError('pause failed');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek');
  }

  @override
  Stream<dynamic> get stateEvents => _stateController.stream;

  void emitState(Map<String, Object?> event) {
    _stateController.add(event);
  }

  void dispose() {
    _stateController.close();
  }
}

void main() {
  group('AudioController', () {
    late FakePlatform platform;
    late AudioController controller;

    setUp(() {
      platform = FakePlatform();
      controller = AudioController(platform: platform);
    });

    tearDown(() {
      controller.dispose();
      platform.dispose();
    });

    test('play before init throws', () async {
      expect(() => controller.play(), throwsStateError);
    });

    test('emits state updates from platform events', () async {
      await controller.init(
          const SoundwaveConfig(sampleRate: 48000, bufferSize: 1024, channels: 2));

      final states = <AudioState>[];
      final sub = controller.states.listen(states.add);

      platform.emitState(<String, Object?>{
        'type': 'state',
        'positionMs': 120,
        'durationMs': 1000,
        'isPlaying': true,
        'bufferedMs': 400,
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(states, isNotEmpty);
      final last = states.last;
      expect(last.position, const Duration(milliseconds: 120));
      expect(last.duration, const Duration(milliseconds: 1000));
      expect(last.isPlaying, isTrue);
      expect(last.bufferedPosition, const Duration(milliseconds: 400));

      await sub.cancel();
    });

    test('error events surface in state', () async {
      await controller.init(
          const SoundwaveConfig(sampleRate: 48000, bufferSize: 1024, channels: 2));
      final errors = controller.states.where((s) => s.error != null);

      platform.emitState(<String, Object?>{
        'type': 'error',
        'message': 'network error',
      });

      final first = await errors.first;
      expect(first.error, 'network error');
    });
  });
}
