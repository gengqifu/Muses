#!/usr/bin/env bash
set -euo pipefail

# 简易长时间播放稳定性 smoke 脚本（本地文件）。
# 依赖：flutter、可用设备/模拟器，SOURCE_URL 指向本地音频。

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$APP_ROOT/example"
SOURCE_URL="${SOURCE_URL:-file:///tmp/sample.mp3}"
DURATION_MINUTES="${DURATION_MINUTES:-120}"

echo "==> Building example app in release mode for long-run smoke..."
pushd "$EXAMPLE_DIR" >/dev/null
flutter build apk --release

echo "==> Running long-run playback (~${DURATION_MINUTES}min)..."
flutter run --release -d emulator-5554 \
  --dart-define=SOUNDWAVE_SAMPLE_URL="$SOURCE_URL" \
  --route="/" &
RUN_PID=$!

echo "Playback started (pid=$RUN_PID). Monitor device for crashes/leaks."
echo "Run duration target: ${DURATION_MINUTES} minutes."
echo "Press Ctrl+C to stop."
wait $RUN_PID || true

popd >/dev/null
