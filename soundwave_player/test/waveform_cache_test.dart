import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave_player/soundwave_player.dart';

void main() {
  group('WaveformCache', () {
    test('keeps max samples and buckets min/max', () {
      final cache = WaveformCache(maxSamples: 5);
      cache.addSamples([1, 0.5, -0.5]);
      cache.addSamples([0.2, -1, 0.8]); // will exceed maxSamples

      expect(cache.length, 5); // oldest 1 removed

      final buckets = cache.bucketsForWidth(2);
      expect(buckets, hasLength(2)); // 5 samples / 2 => bucketSize ceil=3 => 2 buckets
      expect(buckets[0].min, closeTo(-0.5, 1e-6));
      expect(buckets[0].max, closeTo(0.5, 1e-6));
      expect(buckets[1].min, closeTo(-1.0, 1e-6));
      expect(buckets[1].max, closeTo(0.8, 1e-6));
    });
  });
}
