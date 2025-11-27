import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave_player/soundwave_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpectrumView perf smoke', () {
    testWidgets('renders repeated updates within budget', (tester) async {
      final bins = List<SpectrumBin>.generate(
          256,
          (i) => SpectrumBin(
                frequency: i * 50.0,
                magnitude: math.sin(i / 10).abs(),
              ));

      final widget = StatefulBuilder(builder: (context, setState) {
        return MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 180,
              child: SpectrumView(
                bins: bins,
                style: const SpectrumStyle(
                    barColor: Colors.cyan, background: Colors.black, barWidth: 2, spacing: 1),
              ),
            ),
          ),
        );
      });

      final start = DateTime.now();
      await tester.pumpWidget(widget);
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final elapsed = DateTime.now().difference(start);
      expect(elapsed, lessThan(const Duration(seconds: 3)));
    });
  });
}
