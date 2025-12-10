import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave_player/soundwave_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('soundwave_player');
  const stateChannel = EventChannel('soundwave_player/events/state');
  const pcmChannel = EventChannel('soundwave_player/events/pcm');
  const spectrumChannel = EventChannel('soundwave_player/events/spectrum');

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, (MethodCall call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockStreamHandler(stateChannel, null);
    messenger.setMockStreamHandler(pcmChannel, null);
    messenger.setMockStreamHandler(spectrumChannel, null);
  });

  test('asset playback pushes pcm/spectrum into buffers', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(
        stateChannel,
        _ListStreamHandler(<Map<String, Object?>>[
          <String, Object?>{'type': 'state', 'positionMs': 0, 'durationMs': 1200, 'isPlaying': true},
          <String, Object?>{'type': 'state', 'positionMs': 50, 'durationMs': 1200, 'isPlaying': true},
        ]));
    messenger.setMockStreamHandler(
        pcmChannel,
        _ListStreamHandler(<Map<String, Object?>>[
          <String, Object?>{'sequence': 1, 'timestampMs': 0, 'samples': <double>[0.1, -0.1]},
          <String, Object?>{'sequence': 2, 'timestampMs': 10, 'samples': <double>[0.2, -0.2]},
          <String, Object?>{'sequence': 3, 'timestampMs': 20, 'samples': <double>[0.3, -0.3]},
        ]));
    messenger.setMockStreamHandler(
        spectrumChannel,
        _ListStreamHandler(<Map<String, Object?>>[
          <String, Object?>{'sequence': 1, 'timestampMs': 0, 'bins': <double>[0.4, 0.2], 'binHz': 100.0},
          <String, Object?>{'sequence': 2, 'timestampMs': 15, 'bins': <double>[0.3, 0.1], 'binHz': 100.0},
        ]));

    final controller = AudioController(platform: SoundwavePlayer());
    await controller.init(
        const SoundwaveConfig(sampleRate: 48000, bufferSize: 2048, channels: 2));
    await controller.load('assets/audio/sample.mp3');
    await controller.play();

    await Future<void>.delayed(const Duration(milliseconds: 20));

    final pcm = controller.pcmBuffer.drain(10);
    final spectrum = controller.spectrumBuffer.drain(10);

    expect(
        calls.where((c) => c.method == 'load' && c.arguments is Map && c.arguments['source'] == 'assets/audio/sample.mp3'),
        isNotEmpty,
        reason: 'asset source should be forwarded to platform');
    expect(pcm.frames.length, greaterThanOrEqualTo(3));
    expect(spectrum.frames.length, greaterThanOrEqualTo(2));
    expect(controller.state.isPlaying, isTrue);

    controller.dispose();
  });

  test('URL playback buffers pcm/spectrum and keeps controller running', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(
        stateChannel,
        _ListStreamHandler(<Map<String, Object?>>[
          <String, Object?>{'type': 'state', 'positionMs': 0, 'durationMs': 2000, 'isPlaying': true},
          <String, Object?>{'type': 'state', 'positionMs': 120, 'durationMs': 2000, 'bufferedMs': 800, 'isPlaying': true},
        ]));
    messenger.setMockStreamHandler(
        pcmChannel,
        _ListStreamHandler(<Map<String, Object?>>[
          <String, Object?>{'sequence': 10, 'timestampMs': 0, 'samples': <double>[0.1, -0.1]},
          <String, Object?>{'sequence': 11, 'timestampMs': 30, 'samples': <double>[0.2, -0.2]},
        ]));
    messenger.setMockStreamHandler(
        spectrumChannel,
        _ListStreamHandler(<Map<String, Object?>>[
          <String, Object?>{'sequence': 10, 'timestampMs': 0, 'bins': <double>[0.5, 0.25], 'binHz': 80.0},
        ]));

    final controller = AudioController(platform: SoundwavePlayer());
    await controller.init(
        const SoundwaveConfig(sampleRate: 44100, bufferSize: 1024, channels: 2));
    await controller.load('https://example.com/stream.mp3');
    await controller.play();

    await Future<void>.delayed(const Duration(milliseconds: 20));

    final pcm = controller.pcmBuffer.drain(10);
    final spectrum = controller.spectrumBuffer.drain(10);

    expect(
        calls.where((c) => c.method == 'load' && c.arguments is Map && c.arguments['source'] == 'https://example.com/stream.mp3'),
        isNotEmpty,
        reason: 'url source should be forwarded to platform');
    expect(pcm.frames.length, greaterThanOrEqualTo(2));
    expect(spectrum.frames.length, 1);
    expect(controller.state.isPlaying, isTrue);

    controller.dispose();
  });
}

class _ListStreamHandler extends MockStreamHandler {
  const _ListStreamHandler(this.events);

  final List<Map<String, Object?>> events;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink eventsSink) {
    for (final e in events) {
      eventsSink.success(e);
    }
    eventsSink.endOfStream();
  }

  @override
  void onCancel(Object? arguments) {
    // no-op
  }
}
