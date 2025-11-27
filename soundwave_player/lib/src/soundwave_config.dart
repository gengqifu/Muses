class SoundwaveConfig {
  final int sampleRate;
  final int bufferSize;
  final int channels;
  final int? pcmMaxFps;
  final int? pcmFramesPerPush;
  final int? pcmMaxPending;

  const SoundwaveConfig({
    required this.sampleRate,
    required this.bufferSize,
    required this.channels,
    this.pcmMaxFps,
    this.pcmFramesPerPush,
    this.pcmMaxPending,
  });

  void validate() {
    if (sampleRate <= 0) {
      throw ArgumentError.value(sampleRate, 'sampleRate', 'must be > 0');
    }
    if (bufferSize <= 0) {
      throw ArgumentError.value(bufferSize, 'bufferSize', 'must be > 0');
    }
    if (channels <= 0) {
      throw ArgumentError.value(channels, 'channels', 'must be > 0');
    }
    if (pcmMaxFps != null && pcmMaxFps! <= 0) {
      throw ArgumentError.value(pcmMaxFps, 'pcmMaxFps', 'must be > 0');
    }
    if (pcmFramesPerPush != null && pcmFramesPerPush! <= 0) {
      throw ArgumentError.value(pcmFramesPerPush, 'pcmFramesPerPush', 'must be > 0');
    }
    if (pcmMaxPending != null && pcmMaxPending! < 0) {
      throw ArgumentError.value(pcmMaxPending, 'pcmMaxPending', 'must be >= 0');
    }
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'sampleRate': sampleRate,
      'bufferSize': bufferSize,
      'channels': channels,
    };
    final visualization = <String, Object?>{};
    if (pcmMaxFps != null) visualization['pcmMaxFps'] = pcmMaxFps;
    if (pcmFramesPerPush != null) visualization['pcmFramesPerPush'] = pcmFramesPerPush;
    if (pcmMaxPending != null) visualization['pcmMaxPending'] = pcmMaxPending;
    if (visualization.isNotEmpty) {
      map['visualization'] = visualization;
    }
    return map;
  }
}
