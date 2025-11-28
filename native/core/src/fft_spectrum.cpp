#include "fft_spectrum.h"

#include <cmath>
#include <complex>
#include <vector>

namespace sw {

namespace {

inline float HannWindow(int n, int N) {
  return 0.5f * (1.0f - std::cos(2.0f * static_cast<float>(M_PI) * n / static_cast<float>(N - 1)));
}

inline float HammingWindow(int n, int N) {
  return 0.54f - 0.46f * std::cos(2.0f * static_cast<float>(M_PI) * n / static_cast<float>(N - 1));
}

}  // namespace

std::vector<float> ComputeSpectrum(const std::vector<float>& samples, int sample_rate,
                                   const SpectrumConfig& cfg) {
  const int N = cfg.window_size;
  if (N <= 0 || sample_rate <= 0) {
    return {};
  }
  if (static_cast<int>(samples.size()) < N) {
    return {};
  }

  std::vector<float> windowed(N, 0.0f);
  for (int i = 0; i < N; ++i) {
    float w = 1.0f;
    switch (cfg.window) {
      case WindowType::kHann:
        w = HannWindow(i, N);
        break;
      case WindowType::kHamming:
        w = HammingWindow(i, N);
        break;
      default:
        w = 1.0f;
        break;
    }
    windowed[i] = samples[i] * w;
  }

  std::vector<float> spectrum(static_cast<size_t>(N / 2 + 1), 0.0f);
  const float norm = 1.0f / static_cast<float>(N);
  for (int k = 0; k <= N / 2; ++k) {
    std::complex<float> acc(0.0f, 0.0f);
    const float angleCoef = -2.0f * static_cast<float>(M_PI) * k / static_cast<float>(N);
    for (int n = 0; n < N; ++n) {
      const float angle = angleCoef * n;
      acc += std::complex<float>(std::cos(angle), std::sin(angle)) * windowed[n];
    }
    const float mag2 = (acc.real() * acc.real() + acc.imag() * acc.imag()) * norm;
    spectrum[static_cast<size_t>(k)] = cfg.power_spectrum ? mag2 : std::sqrt(mag2);
  }

  return spectrum;
}

}  // namespace sw
