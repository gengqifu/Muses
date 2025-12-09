#import "SWVisBridge.h"
#import "SWVisVDSP.h"

@interface SWVisBridge () {
  sw_vis_vdsp_handle *_h;
}
@property(nonatomic, weak) id<SWVisCallback> callback;
@end

static void pcm_cb(const float *data, int frames, int channels, int sample_rate,
                   int64_t timestamp_ms, void *user_data) {
  SWVisBridge *bridge = (__bridge SWVisBridge *)user_data;
  id<SWVisCallback> cb = [bridge callback];
  if (!cb) return;
  NSData *pcm = [NSData dataWithBytes:data length:sizeof(float) * frames * channels];
  [cb onPcm:pcm frames:frames channels:channels timestampMs:timestamp_ms];
}

static void spectrum_cb(const float *bins, int num_bins, int window_size, int sample_rate,
                        int64_t timestamp_ms, void *user_data) {
  SWVisBridge *bridge = (__bridge SWVisBridge *)user_data;
  id<SWVisCallback> cb = [bridge callback];
  if (!cb) return;
  NSData *spec = [NSData dataWithBytes:bins length:sizeof(float) * num_bins];
  [cb onSpectrum:spec windowSize:window_size sampleRate:sample_rate timestampMs:timestamp_ms];
}

@implementation SWVisBridge

- (instancetype)initWithSampleRate:(int)sr
                           channels:(int)ch
                   framesPerBuffer:(int)fpb
                         pcmMaxFps:(int)pcmFps
                    spectrumMaxFps:(int)specFps {
  self = [super init];
  if (self) {
    sw_vis_vdsp_config cfg = {0};
    cfg.sample_rate = sr > 0 ? sr : 44100;
    cfg.channels = ch > 0 ? ch : 2;
    cfg.frames_per_buffer = fpb > 0 ? fpb : 256;
    cfg.pcm_max_fps = pcmFps > 0 ? pcmFps : 60;
    cfg.spectrum_max_fps = specFps > 0 ? specFps : 30;
    cfg.window_size = cfg.frames_per_buffer;
    _h = sw_vis_vdsp_create(cfg);
  }
  return self;
}

- (void)dealloc {
  if (_h) {
    sw_vis_vdsp_stop(_h);
    sw_vis_vdsp_destroy(_h);
  }
}

- (void)setCallback:(id<SWVisCallback>)callback {
  _callback = callback;
}

- (void)start {
  if (!_h) return;
  sw_vis_vdsp_set_pcm_cb(_h, pcm_cb, (__bridge void *)self);
  sw_vis_vdsp_set_spectrum_cb(_h, spectrum_cb, (__bridge void *)self);
  sw_vis_vdsp_start(_h);
}

- (void)pause {
  if (!_h) return;
  sw_vis_vdsp_pause(_h);
}

- (void)resume {
  if (!_h) return;
  sw_vis_vdsp_resume(_h);
}

- (void)seek:(int64_t)positionMs {
  if (!_h) return;
  sw_vis_vdsp_seek(_h, positionMs);
}

- (void)stop {
  if (!_h) return;
  sw_vis_vdsp_stop(_h);
}

@end
