/// Dart-side audio状态对象，供 UI/Controller 使用。
class AudioState {
  const AudioState({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isBuffering,
    this.bufferedPosition,
    this.levels,
    this.spectrum,
    this.error,
  });

  factory AudioState.initial() => const AudioState(
        position: Duration.zero,
        duration: Duration.zero,
        isPlaying: false,
        isBuffering: false,
        bufferedPosition: Duration.zero,
        levels: <double>[],
        spectrum: <double>[],
      );

  final Duration position;
  final Duration duration;
  final Duration? bufferedPosition;
  final bool isPlaying;
  final bool isBuffering;
  final List<double>? levels; // per-channel peak/rms 等
  final List<double>? spectrum; // FFT 结果
  final String? error;

  AudioState copyWith({
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    bool? isPlaying,
    bool? isBuffering,
    List<double>? levels,
    List<double>? spectrum,
    String? error,
  }) {
    return AudioState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      levels: levels ?? this.levels,
      spectrum: spectrum ?? this.spectrum,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'AudioState(position: $position, duration: $duration, buffered: $bufferedPosition, '
        'isPlaying: $isPlaying, isBuffering: $isBuffering, error: $error)';
  }
}
