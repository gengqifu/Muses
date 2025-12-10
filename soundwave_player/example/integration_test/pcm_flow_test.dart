import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soundwave_player/soundwave_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('soundwave_player');
  const stateChannel = EventChannel('soundwave_player/events/state');
  const pcmChannel = EventChannel('soundwave_player/events/pcm');
  const spectrumChannel = EventChannel('soundwave_player/events/spectrum');

  testWidgets('asset/URL playback + control flow emits pcm/spectrum', (tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      calls.add(call);
      return null;
    });

    final stateHandler = _PumpStreamHandler();
    final pcmHandler = _PumpStreamHandler();
    final spectrumHandler = _PumpStreamHandler();
    messenger.setMockStreamHandler(stateChannel, stateHandler);
    messenger.setMockStreamHandler(pcmChannel, pcmHandler);
    messenger.setMockStreamHandler(spectrumChannel, spectrumHandler);

    final controller = AudioController(platform: SoundwavePlayer());
    await controller.init(
        const SoundwaveConfig(sampleRate: 48000, bufferSize: 2048, channels: 2));
    await controller.load('assets/audio/sample.mp3');
    await controller.play();

    pcmHandler.emit(<String, Object?>{
      'sequence': 1,
      'timestampMs': 0,
      'samples': <double>[0.1, -0.1],
    });
    pcmHandler.emit(<String, Object?>{
      'sequence': 2,
      'timestampMs': 10,
      'samples': <double>[0.2, -0.2],
    });
    spectrumHandler.emit(<String, Object?>{
      'sequence': 1,
      'timestampMs': 0,
      'bins': <double>[0.3, 0.2],
      'binHz': 50.0,
    });
    stateHandler.emit(<String, Object?>{
      'type': 'state',
      'isPlaying': true,
      'positionMs': 10,
      'durationMs': 1000,
    });

    await tester.pump(const Duration(milliseconds: 20));
    final pcm1 = controller.pcmBuffer.drain(10);
    final spec1 = controller.spectrumBuffer.drain(10);
    expect(pcm1.frames.length, 2);
    expect(spec1.frames.length, 1);
    expect(controller.state.isPlaying, isTrue);

    await controller.pause();
    stateHandler.emit(<String, Object?>{
      'type': 'state',
      'isPlaying': false,
      'positionMs': 20,
      'durationMs': 1000,
    });
    await tester.pump(const Duration(milliseconds: 10));
    expect(controller.state.isPlaying, isFalse);

    await controller.seek(const Duration(milliseconds: 5));
    pcmHandler.emit(<String, Object?>{
      'sequence': 3,
      'timestampMs': 5,
      'samples': <double>[0.3, -0.3],
    });
    await tester.pump(const Duration(milliseconds: 20));
    final pcm2 = controller.pcmBuffer.drain(10);
    expect(pcm2.frames.map((f) => f.sequence), [3]);

    expect(calls.map((c) => c.method),
        containsAll(<String>['load', 'play', 'pause', 'seek']));
  });
}

class _PumpStreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    _sink = events;
  }

  @override
  void onCancel(Object? arguments) {
    _sink = null;
  }

  void emit(Map<String, Object?> event) {
    _sink?.success(event);
  }
}
