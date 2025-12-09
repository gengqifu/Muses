#import <Foundation/Foundation.h>

// 回调签名（交错 PCM，float32）
typedef void (*sw_vis_pcm_cb)(const float *data, int frames, int channels, int sample_rate,
                              int64_t timestamp_ms, void *user_data);
typedef void (*sw_vis_spectrum_cb)(const float *bins, int num_bins, int window_size,
                                   int sample_rate, int64_t timestamp_ms, void *user_data);

typedef struct sw_vis_vdsp_handle sw_vis_vdsp_handle;

typedef struct {
  int sample_rate;       // 默认 44100
  int channels;          // 默认 2
  int frames_per_buffer; // 默认 256
  int pcm_max_fps;       // 默认 60（简单 sleep 控制）
  int spectrum_max_fps;  // 默认 30
  int window_size;       // 默认 frames_per_buffer
} sw_vis_vdsp_config;

// 创建/销毁
sw_vis_vdsp_handle *sw_vis_vdsp_create(sw_vis_vdsp_config cfg);
void sw_vis_vdsp_destroy(sw_vis_vdsp_handle *h);

// 回调注册
void sw_vis_vdsp_set_pcm_cb(sw_vis_vdsp_handle *h, sw_vis_pcm_cb cb, void *ud);
void sw_vis_vdsp_set_spectrum_cb(sw_vis_vdsp_handle *h, sw_vis_spectrum_cb cb, void *ud);

// 启停（内部生成 1kHz 正弦 → Hann 窗 → vDSP FFT）
void sw_vis_vdsp_start(sw_vis_vdsp_handle *h);
void sw_vis_vdsp_stop(sw_vis_vdsp_handle *h);

