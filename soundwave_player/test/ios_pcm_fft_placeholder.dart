import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave_player/soundwave_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS PCM/FFT placeholder', () {
    test('buffers pcm and spectrum events in order', () async {
      final pcmController = StreamController<Map<String, Object?>>.broadcast();
      final spectrumController = StreamController<Map<String, Object?>>.broadcast();
      final pcmBuffer = PcmBuffer(stream: pcmController.stream, maxFrames: 5);
      final spectrumBuffer = SpectrumBuffer(stream: spectrumController.stream, maxFrames: 5);

      pcmController.add(<String, Object?>{
        'sequence': 1,
        'timestampMs': 100,
        'samples': <double>[0.1, -0.1],
      });
      spectrumController.add(<String, Object?>{
        'sequence': 1,
        'timestampMs': 100,
        'bins': <double>[0.01, 0.02],
        'binHz': 10.0,
      });
      await Future<void>.delayed(Duration.zero);

      final pcm = pcmBuffer.drain(10);
      final spectrum = spectrumBuffer.drain(10);
      expect(pcm.frames, hasLength(1));
      expect(pcm.frames.first.timestampMs, 100);
      expect(pcm.frames.first.samples, containsAllInOrder(<double>[0.1, -0.1]));
      expect(spectrum.frames, hasLength(1));
      expect(spectrum.frames.first.bins, isNotEmpty);

      pcmBuffer.dispose();
      spectrumBuffer.dispose();
      await pcmController.close();
      await spectrumController.close();
    });

    test('resets on timestamp rollback to accept seek', () async {
      final pcmController = StreamController<Map<String, Object?>>.broadcast();
      final pcmBuffer = PcmBuffer(stream: pcmController.stream, maxFrames: 5);

      pcmController.add(<String, Object?>{
        'sequence': 1,
        'timestampMs': 200,
        'samples': <double>[0.1],
      });
      await Future<void>.delayed(Duration.zero);
      expect(pcmBuffer.length, 1);

      pcmController.add(<String, Object?>{
        'sequence': 2,
        'timestampMs': 50, // rollback simulating seek
        'samples': <double>[0.2],
      });
      await Future<void>.delayed(Duration.zero);
      final res = pcmBuffer.drain(10);
      expect(res.frames.first.timestampMs, 50);
      expect(pcmBuffer.length, 0);

      pcmBuffer.dispose();
      await pcmController.close();
    });
  }, skip: 'iOS PCM tap/FFT native implementation pending (Story 16) — placeholder test only');
}
