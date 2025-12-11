#!/usr/bin/env bash
set -euo pipefail

# 简单的许可证/依赖敏感词扫描，避免误引 FFmpeg 或 GPL 依赖。
# 仅扫描代码/配置文件，跳过文档与 LICENSE/NOTICE。

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PATTERNS=(
  "ffmpeg"
  "gpl"
)

TARGET_DIRS=(
  "soundwave_player"
  "native"
  "integration"
  "scripts"
)

EXCLUDES=(
  "--glob=!**/*.md"
  "--glob=!scripts/check_license.sh"
  "--glob=!**/LICENSE*"
  "--glob=!**/NOTICE*"
  "--glob=!**/DEPENDENCIES*"
  "--glob=!**/CHANGELOG*"
  "--glob=!**/.git/**"
  "--glob=!**/build/**"
  "--glob=!**/DerivedData/**"
)

has_issue=0

for pattern in "${PATTERNS[@]}"; do
  if ! rg -i "${EXCLUDES[@]}" "$pattern" "${TARGET_DIRS[@]}" >/tmp/license_scan.out 2>/tmp/license_scan.err; then
    # rg returns non-zero on no matches; treat as success in that case.
    if grep -q "pattern not found" /tmp/license_scan.err || [[ ! -s /tmp/license_scan.out ]]; then
      continue
    fi
  fi
  if [[ -s /tmp/license_scan.out ]]; then
    echo "Found disallowed pattern \"$pattern\" in code/config files:"
    cat /tmp/license_scan.out
    has_issue=1
  fi
done

rm -f /tmp/license_scan.out /tmp/license_scan.err

if [[ $has_issue -ne 0 ]]; then
  echo "[license-scan] FAILED: please remove references above (docs/Licenses are allowed separately)." >&2
  exit 1
fi

echo "[license-scan] OK: no disallowed patterns found in code/config files."
