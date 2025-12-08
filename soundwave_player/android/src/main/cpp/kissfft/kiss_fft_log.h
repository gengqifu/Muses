#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>
#include <stdio.h>

static inline void KISS_FFT_WARNING(const char *fmt, ...) {
  // Optional logging hook; noop to avoid extra deps.
  (void)fmt;
}

static inline void KISS_FFT_ERROR(const char *fmt, ...) {
  // Optional error hook; noop to avoid aborting builds.
  (void)fmt;
}

#ifdef __cplusplus
}
#endif
