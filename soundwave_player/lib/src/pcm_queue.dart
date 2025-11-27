import 'dart:collection';

import 'pcm_frame.dart';

class PcmDequeueResult {
  const PcmDequeueResult(this.frames, {this.droppedBefore = 0});

  final List<PcmFrame> frames;
  final int droppedBefore;
}

/// 简易 PCM 缓存队列：FIFO，超过容量时丢弃最旧帧并累计 dropped 计数。
class PcmQueue {
  PcmQueue({this.maxFrames = 30}) : assert(maxFrames > 0);

  final int maxFrames;
  final ListQueue<PcmFrame> _queue = ListQueue<PcmFrame>();
  int _dropped = 0;

  void push(PcmFrame frame) {
    _queue.addLast(frame);
    if (_queue.length > maxFrames) {
      _queue.removeFirst();
      _dropped++;
    }
  }

  PcmDequeueResult take(int maxCount) {
    if (maxCount <= 0) {
      return PcmDequeueResult(const <PcmFrame>[], droppedBefore: _dropped);
    }
    final int count = maxCount > _queue.length ? _queue.length : maxCount;
    final frames = <PcmFrame>[];
    for (int i = 0; i < count; ++i) {
      frames.add(_queue.removeFirst());
    }
    final droppedBefore = _dropped;
    _dropped = 0;
    return PcmDequeueResult(frames, droppedBefore: droppedBefore);
  }

  int get length => _queue.length;
  int get dropped => _dropped;

  void clear() {
    _queue.clear();
    _dropped = 0;
  }
}
