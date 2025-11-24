#!/usr/bin/env bash
set -euo pipefail

# Build FFmpeg static libraries for iOS arm64.
# Prerequisites: Xcode command line tools installed. Run from any directory.

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
FFSRC="${FFSRC:-"$ROOT_DIR/ffmpeg"}"
PREFIX="${PREFIX:-"$FFSRC/build/ios/arm64"}"

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
CC_BIN="$(xcrun --sdk iphoneos -f clang)"
CPU_CORES="$(sysctl -n hw.ncpu)"

cd "$FFSRC"

# If you change configure flags/targets, clean first:
# make distclean || true

./configure \
  --prefix="$PREFIX" \
  --enable-cross-compile \
  --target-os=darwin \
  --arch=arm64 \
  --cc="$CC_BIN" \
  --sysroot="$SDK_PATH" \
  --enable-pic \
  --disable-shared \
  --enable-static \
  --disable-programs \
  --disable-doc \
  --disable-debug \
  --enable-small \
  --disable-everything \
  --enable-decoder=aac,mp3,flac,pcm_s16le,pcm_f32le \
  --enable-demuxer=mov,mp3,aac,flac,wav \
  --enable-parser=aac,mpegaudio,flac \
  --enable-protocol=file,http,https

make -j"$CPU_CORES"
make install

echo "FFmpeg built for iOS arm64 at: $PREFIX"
