import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pcm_frame.dart';

class WaveformView extends StatelessWidget {
  const WaveformView({super.key, required this.frames, this.color = Colors.blue, this.background});

  final List<PcmFrame> frames;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(frames, color: color, background: background ?? Colors.black),
      size: const Size(double.infinity, 120),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.frames, {required this.color, required this.background});

  final List<PcmFrame> frames;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()..color = background;
    canvas.drawRect(Offset.zero & size, paintBg);

    if (frames.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final totalSamples = frames.fold<int>(0, (sum, f) => sum + f.samples.length);
    final height = size.height;
    final width = size.width;
    final List<double> samples = [];
    for (final f in frames) {
      samples.addAll(f.samples);
    }
    if (samples.isEmpty) return;

    // 抽稀为 width 像素的 bucket，取 min/max。
    final bucketSize = math.max(1, (samples.length / width).ceil());
    final int buckets = (samples.length / bucketSize).ceil();
    for (int i = 0; i < buckets; i++) {
      final start = i * bucketSize;
      final end = math.min(start + bucketSize, samples.length);
      double minV = 1.0;
      double maxV = -1.0;
      for (int j = start; j < end; j++) {
        final v = samples[j].clamp(-1.0, 1.0);
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
      final x = (i / buckets) * width;
      final yMin = height * (0.5 - minV * 0.5);
      final yMax = height * (0.5 - maxV * 0.5);
      path.moveTo(x, yMin);
      path.lineTo(x, yMax);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.frames != frames || oldDelegate.color != color || oldDelegate.background != background;
  }
}
