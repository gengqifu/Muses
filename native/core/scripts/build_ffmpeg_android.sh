#!/usr/bin/env bash
set -euo pipefail

# Build FFmpeg static libraries for Android (default arm64-v8a).
# Prerequisites: Android NDK installed; set NDK env var or edit below.

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
FFSRC="${FFSRC:-"$ROOT_DIR/ffmpeg"}"
# 默认使用本机已安装的 NDK 26.1.10909125，可通过环境变量 NDK 覆盖。
NDK="${NDK:-/Users/gengqifu/Library/Android/sdk/ndk/26.1.10909125}"
API="${API:-24}"
ABI="${ABI:-arm64-v8a}"

case "$ABI" in
  arm64-v8a)
    TARGET_OS=android
    ARCH=aarch64
    TRIPLE=aarch64-linux-android
    ;;
  armeabi-v7a)
    TARGET_OS=android
    ARCH=arm
    TRIPLE=armv7a-linux-androideabi
    ;;
  x86_64)
    TARGET_OS=android
    ARCH=x86_64
    TRIPLE=x86_64-linux-android
    ;;
  *)
    echo "Unsupported ABI: $ABI"
    exit 1
    ;;
esac

TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/darwin-x86_64"
SYSROOT="$TOOLCHAIN/sysroot"
CC_BIN="$TOOLCHAIN/bin/${TRIPLE}${API}-clang"
CPU_CORES="$(sysctl -n hw.ncpu)"
PREFIX="${PREFIX:-"$FFSRC/build/android/$ABI"}"

cd "$FFSRC"

# If you change configure flags/targets, clean first:
# make distclean || true

./configure \
  --prefix="$PREFIX" \
  --enable-cross-compile \
  --target-os="$TARGET_OS" \
  --arch="$ARCH" \
  --cc="$CC_BIN" \
  --sysroot="$SYSROOT" \
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

echo "FFmpeg built for $ABI at: $PREFIX"
