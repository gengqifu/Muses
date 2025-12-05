// Integration smoke: platform decode produces PCM frames on device.
// Run manually with: flutter test integration_test --dart-define=RUN_PLATFORM_DECODE_SMOKE=true

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundwave_player/soundwave_player.dart';

const bool _runSmoke =
    bool.fromEnvironment('RUN_PLATFORM_DECODE_SMOKE', defaultValue: false);

Future<String> _copyAssetToTemp(String assetPath, {String? filename}) async {
  final data = await rootBundle.load(assetPath);
  final tmpDir = await getTemporaryDirectory();
  final file =
      File('${tmpDir.path}/${filename ?? assetPath.split('/').last}');
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return file.uri.toString();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('platform decode emits PCM frames', (tester) async {
    if (!_runSmoke) {
      return;
    }
    final controller = AudioController();
    await controller.init(const SoundwaveConfig(
      sampleRate: 44100,
      bufferSize: 2048,
      channels: 2,
      // 频谱不验证，此处只关心 PCM。
    ));

    final uri = await _copyAssetToTemp('test/assets/audio/sine_1k.wav');
    await controller.load(uri);
    await controller.play();

    // 给解码与回放一点时间产生 PCM 事件。
    await Future<void>.delayed(const Duration(seconds: 1));

    final frames = controller.pcmBuffer.drain(10).frames;
    expect(frames.isNotEmpty, true, reason: 'should receive PCM frames');
    expect(frames.first.samples.isNotEmpty, true);
    expect(frames.first.samples.first.isFinite, true);
    // 简单检查双声道交错长度为偶数。
    expect(frames.first.samples.length.isEven, true);

    await controller.stop();
    controller.dispose();
  });
}
