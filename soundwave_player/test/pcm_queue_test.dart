import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave_player/soundwave_player.dart';

void main() {
  group('PcmQueue', () {
    test('maintains FIFO order', () {
      final queue = PcmQueue(maxFrames: 5);
      queue.push(const PcmFrame(sequence: 1, timestampMs: 0, samples: [0.1, 0.2]));
      queue.push(const PcmFrame(sequence: 2, timestampMs: 10, samples: [0.3, 0.4]));
      queue.push(const PcmFrame(sequence: 3, timestampMs: 20, samples: [0.5, 0.6]));

      final result = queue.take(3);
      expect(result.droppedBefore, 0);
      expect(result.frames.map((f) => f.sequence).toList(), [1, 2, 3]);
      expect(queue.length, 0);
    });

    test('drops oldest when over capacity and reports dropped count', () {
      final queue = PcmQueue(maxFrames: 2);
      queue.push(const PcmFrame(sequence: 1, timestampMs: 0, samples: [0.1]));
      queue.push(const PcmFrame(sequence: 2, timestampMs: 5, samples: [0.2]));
      queue.push(const PcmFrame(sequence: 3, timestampMs: 10, samples: [0.3]));

      expect(queue.length, 2);
      expect(queue.dropped, 1);

      final result = queue.take(10);
      expect(result.droppedBefore, 1);
      expect(result.frames.map((f) => f.sequence).toList(), [2, 3]);
      expect(queue.length, 0);
      expect(queue.dropped, 0);
    });

    test('take respects maxCount for backpressure', () {
      final queue = PcmQueue(maxFrames: 4);
      queue.push(const PcmFrame(sequence: 1, timestampMs: 0, samples: [0.1]));
      queue.push(const PcmFrame(sequence: 2, timestampMs: 5, samples: [0.2]));
      queue.push(const PcmFrame(sequence: 3, timestampMs: 10, samples: [0.3]));

      final first = queue.take(1);
      expect(first.frames.map((f) => f.sequence).toList(), [1]);
      expect(first.droppedBefore, 0);
      expect(queue.length, 2);

      final second = queue.take(5);
      expect(second.frames.map((f) => f.sequence).toList(), [2, 3]);
      expect(second.droppedBefore, 0);
      expect(queue.length, 0);
    });

    test('dropped count accumulates until take reports it', () {
      final queue = PcmQueue(maxFrames: 2);
      for (int i = 0; i < 5; i++) {
        queue.push(PcmFrame(sequence: i + 1, timestampMs: i * 5, samples: const [0.1]));
      }
      expect(queue.dropped, 3);

      final result = queue.take(2);
      expect(result.droppedBefore, 3);
      expect(result.frames.map((f) => f.sequence).toList(), [4, 5]);
      expect(queue.dropped, 0);
    });
  });
}
