import 'package:flutter_test/flutter_test.dart';

/// 面向原生 FFT 的契约测试（Android）。
/// TODO: 实现 KissFFT 后取消 skip，改为真实校验频谱事件。
void main() {
  group('Android FFT contract', () {
    test(
      'native FFT emits spectrum bins for 1kHz sine',
      () {
        // 占位：待原生 FFT 接入后，验证返回的 binHz、幅度峰值落在 1kHz 附近。
        expect(true, isTrue);
      },
      skip: 'Pending Android core KissFFT implementation',
    );
  });
}
