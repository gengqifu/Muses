#import "SWVisVDSP.h"
#import <Accelerate/Accelerate.h>
#import <math.h>
#import <pthread.h>
#include <stdlib.h>

struct sw_vis_vdsp_handle {
  sw_vis_vdsp_config cfg;
  sw_vis_pcm_cb pcm_cb;
  sw_vis_spectrum_cb spec_cb;
  void *pcm_ud;
  void *spec_ud;
  pthread_t thread;
  int running;
  int paused;
  int64_t ts_ms;
  float phase;
};

static void *sw_vis_vdsp_thread(void *arg) {
  sw_vis_vdsp_handle *h = (sw_vis_vdsp_handle *)arg;
  const int frames = h->cfg.frames_per_buffer > 0 ? h->cfg.frames_per_buffer : 256;
  const int ch = h->cfg.channels > 0 ? h->cfg.channels : 2;
  const int sr = h->cfg.sample_rate > 0 ? h->cfg.sample_rate : 44100;
  const int win = h->cfg.window_size > 0 ? h->cfg.window_size : frames;
  const float tone = 1000.0f;
  const float two_pi = 2.f * (float)M_PI;
  const int64_t frame_dur_ms = (int64_t)((frames * 1000) / sr);

  float *pcm = (float *)calloc((size_t)frames * (size_t)ch, sizeof(float));
  float *mono = (float *)calloc((size_t)win, sizeof(float));
  float *real = (float *)calloc((size_t)win, sizeof(float));
  float *imag = (float *)calloc((size_t)win, sizeof(float));
  float *mag = (float *)calloc((size_t)(win / 2 + 1), sizeof(float));

  double e_win = 0.0;
  for (int i = 0; i < win; ++i) {
    double w = 0.5 * (1.0 - cos(2.0 * M_PI * i / (win - 1)));
    e_win += w * w;
  }
  const double norm = 2.0 / (win * e_win);

  while (h->running) {
    if (h->paused) {
      usleep(5000);
      continue;
    }
    float phase = h->phase;
    for (int i = 0; i < frames; ++i) {
      float sample = sinf(two_pi * tone * ((float)i / sr) + phase);
      for (int c = 0; c < ch; ++c) {
        pcm[i * ch + c] = sample;
      }
    }
    phase += two_pi * tone * ((float)frames / sr);
    h->phase = phase;

    if (h->pcm_cb) {
      h->pcm_cb(pcm, frames, ch, sr, h->ts_ms, h->pcm_ud);
    }

    float *monoPtr = mono;
    for (int i = 0; i < win; ++i) {
      float w = 0.5f * (1.0f - cosf(2.0f * (float)M_PI * i / (win - 1)));
      monoPtr[i] = pcm[i * ch] * w;
    }

    for (int i = 0; i < win; ++i) {
      real[i] = monoPtr[i];
      imag[i] = 0.0f;
    }
    DSPSplitComplex split = {real, imag};
    FFTSetup setup = vDSP_create_fftsetup(log2((double)win), kFFTRadix2);
    vDSP_fft_zip(setup, &split, 1, log2((double)win), FFT_FORWARD);
    vDSP_destroy_fftsetup(setup);

    int half = win / 2 + 1;
    for (int k = 0; k < half; ++k) {
      float r = real[k];
      float im = imag[k];
      mag[k] = sqrtf(r * r + im * im) * (float)norm;
    }

    if (h->spec_cb) {
      h->spec_cb(mag, half, win, sr, h->ts_ms, h->spec_ud);
    }

    h->ts_ms += frame_dur_ms;
    int pcm_sleep = h->cfg.pcm_max_fps > 0 ? (1000 / h->cfg.pcm_max_fps) : 0;
    if (pcm_sleep > 0) {
      usleep((useconds_t)pcm_sleep * 1000);
    } else {
      usleep(1000);
    }
  }

  free(pcm);
  free(mono);
  free(real);
  free(imag);
  free(mag);
  return NULL;
}

sw_vis_vdsp_handle *sw_vis_vdsp_create(sw_vis_vdsp_config cfg) {
  sw_vis_vdsp_handle *h = (sw_vis_vdsp_handle *)calloc(1, sizeof(sw_vis_vdsp_handle));
  h->cfg = cfg;
  h->ts_ms = 0;
  h->phase = 0.0f;
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
  h->paused = 0;
  h->ts_ms = 0;
  h->phase = 0.0f;
  pthread_create(&h->thread, NULL, sw_vis_vdsp_thread, h);
}

void sw_vis_vdsp_pause(sw_vis_vdsp_handle *h) {
  if (!h) return;
  h->paused = 1;
}

void sw_vis_vdsp_resume(sw_vis_vdsp_handle *h) {
  if (!h) return;
  h->paused = 0;
}

void sw_vis_vdsp_seek(sw_vis_vdsp_handle *h, int64_t position_ms) {
  if (!h) return;
  h->ts_ms = position_ms;
  h->phase = 0.0f;
}

void sw_vis_vdsp_stop(sw_vis_vdsp_handle *h) {
  if (!h || !h->running) return;
  h->running = 0;
  pthread_join(h->thread, NULL);
  h->paused = 0;
  h->ts_ms = 0;
  h->phase = 0.0f;
}

