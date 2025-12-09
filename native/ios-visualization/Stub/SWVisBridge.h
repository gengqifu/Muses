#import <Foundation/Foundation.h>

@protocol SWVisCallback <NSObject>
- (void)onPcm:(NSData *)data frames:(NSInteger)frames channels:(NSInteger)channels timestampMs:(int64_t)ts;
- (void)onSpectrum:(NSData *)bins windowSize:(NSInteger)window sampleRate:(NSInteger)sr timestampMs:(int64_t)ts;
@end

@interface SWVisBridge : NSObject
- (instancetype)initWithSampleRate:(int)sr
                           channels:(int)ch
                   framesPerBuffer:(int)fpb
                         pcmMaxFps:(int)pcmFps
                    spectrumMaxFps:(int)specFps;
- (void)setCallback:(id<SWVisCallback>)callback;
- (void)start;
- (void)pause;
- (void)resume;
- (void)seek:(int64_t)positionMs;
- (void)stop;
@end
