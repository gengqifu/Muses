#!/usr/bin/env bash
set -euo pipefail

# 将采集到的 trace/日志归档到 profile/ 目录，便于后续对比。
# 用法：
#   TRACE_FILE=/path/to/trace.json SCENE=local_playback ./scripts/save_trace.sh

TRACE_FILE="${TRACE_FILE:-}"
SCENE="${SCENE:-local}"
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$APP_ROOT/profile}"

if [[ -z "$TRACE_FILE" || ! -f "$TRACE_FILE" ]]; then
  echo "TRACE_FILE 未指定或不存在" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
TS=$(date +"%Y%m%d_%H%M%S")
BASENAME="$(basename "$TRACE_FILE")"
DEST="$OUT_DIR/${SCENE}_${TS}_${BASENAME}"

cp "$TRACE_FILE" "$DEST"
echo "Saved trace to $DEST"
