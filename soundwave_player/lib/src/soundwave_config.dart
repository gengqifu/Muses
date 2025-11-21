class SoundwaveConfig {
  final int sampleRate;
  final int bufferSize;
  final int channels;
  final Map<String, Object?>? visualization;

  const SoundwaveConfig({
    required this.sampleRate,
    required this.bufferSize,
    required this.channels,
    this.visualization,
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
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'sampleRate': sampleRate,
      'bufferSize': bufferSize,
      'channels': channels,
      if (visualization != null) 'visualization': visualization,
    };
  }
}
