#import "SWVisVDSP.h"
#import <Accelerate/Accelerate.h>
#import <math.h>
#import <pthread.h>

struct sw_vis_vdsp_handle {
  sw_vis_vdsp_config cfg;
  sw_vis_pcm_cb pcm_cb;
  sw_vis_spectrum_cb spec_cb;
  void *pcm_ud;
  void *spec_ud;
  pthread_t thread;
  int running;
};

static void *sw_vis_vdsp_thread(void *arg) {
  sw_vis_vdsp_handle *h = (sw_vis_vdsp_handle *)arg;
  const int frames = h->cfg.frames_per_buffer > 0 ? h->cfg.frames_per_buffer : 256;
  const int ch = h->cfg.channels > 0 ? h->cfg.channels : 2;
  const int sr = h->cfg.sample_rate > 0 ? h->cfg.sample_rate : 44100;
  const int win = h->cfg.window_size > 0 ? h->cfg.window_size : frames;
  const float tone = 1000.0f;
  const float two_pi = 2.f * (float)M_PI;
  float phase = 0.0f;
  int64_t ts_ms = 0;
  const int64_t frame_dur_ms = (int64_t)((frames * 1000) / sr);

  NSMutableData *pcm = [NSMutableData dataWithLength:sizeof(float) * frames * ch];
  NSMutableData *mono = [NSMutableData dataWithLength:sizeof(float) * win];
  NSMutableData *realBuf = [NSMutableData dataWithLength:sizeof(double) * win];
  NSMutableData *imagBuf = [NSMutableData dataWithLength:sizeof(double) * win];
  NSMutableData *magBuf = [NSMutableData dataWithLength:sizeof(double) * (win / 2 + 1)];

  // Hann window energy
  double e_win = 0.0;
  for (int i = 0; i < win; ++i) {
    double w = 0.5 * (1.0 - cos(2.0 * M_PI * i / (win - 1)));
    e_win += w * w;
  }
  const double norm = 2.0 / (win * e_win);

  while (h->running) {
    float *pcmPtr = (float *)pcm.mutableBytes;
    for (int i = 0; i < frames; ++i) {
      float sample = sinf(two_pi * tone * ((float)i / sr) + phase);
      for (int c = 0; c < ch; ++c) {
        pcmPtr[i * ch + c] = sample;
      }
    }
    phase += two_pi * tone * ((float)frames / sr);

    // PCM 回调
    if (h->pcm_cb) {
      h->pcm_cb(pcmPtr, frames, ch, sr, ts_ms, h->pcm_ud);
    }

    // 提取单声道
    float *monoPtr = (float *)mono.mutableBytes;
    for (int i = 0; i < win; ++i) {
      monoPtr[i] = pcmPtr[i * ch];
      // Hann window
      float w = 0.5f * (1.0f - cosf(2.0f * (float)M_PI * i / (win - 1)));
      monoPtr[i] *= w;
    }

    // vDSP FFT (real -> split)
    double *real = (double *)realBuf.mutableBytes;
    double *imag = (double *)imagBuf.mutableBytes;
    for (int i = 0; i < win; ++i) {
      real[i] = monoPtr[i];
      imag[i] = 0.0;
    }
    DSPSplitComplexD split = {real, imag};
    FFTSetupD setup = vDSP_create_fftsetupD(log2((double)win), kFFTRadix2);
    vDSP_fft_zipD(setup, &split, 1, log2((double)win), FFT_FORWARD);
    vDSP_destroy_fftsetupD(setup);

    double *mag = (double *)magBuf.mutableBytes;
    int half = win / 2 + 1;
    for (int k = 0; k < half; ++k) {
      double r = real[k];
      double im = imag[k];
      mag[k] = sqrt(r * r + im * im) * norm;
    }

    if (h->spec_cb) {
      // 转 float
      std::vector<float> bins(static_cast<size_t>(half));
      for (int k = 0; k < half; ++k) bins[k] = (float)mag[k];
      h->spec_cb(bins.data(), half, win, sr, ts_ms, h->spec_ud);
    }

    ts_ms += frame_dur_ms;
    // 粗略限速：PCM fps
    int pcm_sleep = h->cfg.pcm_max_fps > 0 ? (1000 / h->cfg.pcm_max_fps) : 0;
    if (pcm_sleep > 0) {
      usleep((useconds_t)pcm_sleep * 1000);
    } else {
      usleep(1000);
    }
  }
  return nullptr;
}

sw_vis_vdsp_handle *sw_vis_vdsp_create(sw_vis_vdsp_config cfg) {
  sw_vis_vdsp_handle *h = (sw_vis_vdsp_handle *)calloc(1, sizeof(sw_vis_vdsp_handle));
  h->cfg = cfg;
  return h;
}

void sw_vis_vdsp_destroy(sw_vis_vdsp_handle *h) {
  if (!h) return;
  sw_vis_vdsp_stop(h);
  free(h);
}

void sw_vis_vdsp_set_pcm_cb(sw_vis_vdsp_handle *h, sw_vis_pcm_cb cb, void *ud) {
  if (!h) return;
  h->pcm_cb = cb;
  h->pcm_ud = ud;
}

void sw_vis_vdsp_set_spectrum_cb(sw_vis_vdsp_handle *h, sw_vis_spectrum_cb cb, void *ud) {
  if (!h) return;
  h->spec_cb = cb;
  h->spec_ud = ud;
}

void sw_vis_vdsp_start(sw_vis_vdsp_handle *h) {
  if (!h || h->running) return;
  h->running = 1;
  pthread_create(&h->thread, nullptr, sw_vis_vdsp_thread, h);
}

void sw_vis_vdsp_stop(sw_vis_vdsp_handle *h) {
  if (!h || !h->running) return;
  h->running = 0;
  pthread_join(h->thread, nullptr);
}

