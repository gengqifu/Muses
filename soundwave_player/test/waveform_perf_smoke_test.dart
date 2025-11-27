import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave_player/soundwave_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WaveformView perf smoke', () {
    testWidgets('renders repeated updates within budget', (tester) async {
      // 构造大样本数据，模拟持续刷新。
      final samples = List<double>.generate(5000, (i) => math.sin(i / 10));
      final frame = PcmFrame(sequence: 1, timestampMs: 0, samples: samples);

      final widget = StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 150,
                  child: WaveformView(
                    frames: [frame],
                    color: Colors.blueAccent,
                    background: Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      );

      final start = DateTime.now();
      await tester.pumpWidget(widget);
      // 进行多次刷新，确保没有明显掉帧/卡顿。
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final elapsed = DateTime.now().difference(start);
      // 设置宽松阈值，确保 smoke 范围内性能正常。
      expect(elapsed, lessThan(const Duration(seconds: 3)));
    });
  });
}
