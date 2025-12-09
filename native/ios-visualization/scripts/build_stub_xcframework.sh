#!/usr/bin/env bash
set -euo pipefail

# 基于占位 C 实现生成 SoundwaveVisualization.xcframework（arm64 设备 + 模拟器）。
# 依赖 Xcode 命令行工具（xcrun/clang/xcodebuild）。
#
# 用法：
#   ./scripts/build_stub_xcframework.sh
# 产物：
#   native/ios-visualization/SoundwaveVisualization.xcframework

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/build"
HEADERS_DIR="$ROOT_DIR/Stub/include"
XC_OUT="$ROOT_DIR/SoundwaveVisualization.xcframework"

rm -rf "$OUT_DIR" "$XC_OUT"
mkdir -p "$OUT_DIR"

LIBTOOL=$(xcrun --sdk iphoneos --find libtool)
CLANG=$(xcrun --sdk iphoneos --find clang)

echo "==> Compile device (arm64)"
DEV_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
"$CLANG" -c "$ROOT_DIR/Stub/SWVisStub.c" \
  -isysroot "$DEV_SDK" \
  -arch arm64 \
  -I "$HEADERS_DIR" \
  -fembed-bitcode \
  -o "$OUT_DIR/swvis_arm64.o"
"$LIBTOOL" -static -o "$OUT_DIR/libswvis_arm64.a" "$OUT_DIR/swvis_arm64.o"

echo "==> Compile simulator (arm64)"
SIM_SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
SIM_CLANG=$(xcrun --sdk iphonesimulator --find clang)
SIM_LIBTOOL=$(xcrun --sdk iphonesimulator --find libtool)

"$SIM_CLANG" -c "$ROOT_DIR/Stub/SWVisStub.c" \
  -isysroot "$SIM_SDK" \
  -arch arm64 \
  -I "$HEADERS_DIR" \
  -fembed-bitcode \
  -o "$OUT_DIR/swvis_sim_arm64.o"
"$SIM_LIBTOOL" -static -o "$OUT_DIR/libswvis_sim_arm64.a" "$OUT_DIR/swvis_sim_arm64.o"

echo "==> Create XCFramework"
xcrun xcodebuild -create-xcframework \
  -library "$OUT_DIR/libswvis_arm64.a" -headers "$HEADERS_DIR" \
  -library "$OUT_DIR/libswvis_sim_arm64.a" -headers "$HEADERS_DIR" \
  -output "$XC_OUT"

echo "OK => $XC_OUT"
