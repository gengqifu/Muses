class PcmFrame {
  const PcmFrame({
    required this.sequence,
    required this.timestampMs,
    required this.samples,
  });

  final int sequence;
  final int timestampMs;
  final List<double> samples;
}
