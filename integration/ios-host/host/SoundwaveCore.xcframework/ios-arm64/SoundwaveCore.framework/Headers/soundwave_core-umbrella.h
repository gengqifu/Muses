#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "fft_bridge.h"
#import "kiss_fft.h"
#import "kiss_fftr.h"
#import "kiss_fft_log.h"
#import "_kiss_fft_guts.h"

FOUNDATION_EXPORT double SoundwaveCoreVersionNumber;
FOUNDATION_EXPORT const unsigned char SoundwaveCoreVersionString[];

