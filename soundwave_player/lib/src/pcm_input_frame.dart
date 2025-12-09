class PcmInputFrame {
  const PcmInputFrame({
    required this.samples,
    required this.sampleRate,
    required this.channels,
    required this.timestampMs,
    required this.sequence,
  });

  final List<double> samples;
  final int sampleRate;
  final int channels;
  final int timestampMs;
  final int sequence;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'samples': samples,
      'sampleRate': sampleRate,
      'channels': channels,
      'timestampMs': timestampMs,
      'sequence': sequence,
      'frameSize': channels > 0 ? samples.length ~/ channels : samples.length,
    };
  }
}
