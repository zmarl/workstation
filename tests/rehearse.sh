#!/usr/bin/env bash
# Run on the old Windows PC (Git Bash + Docker Desktop) before the move:
#   bash tests/rehearse.sh <output-dir>
# 1) shellcheck every script, 2) run tests/container-rehearsal.sh in ubuntu:26.04.
set -Eeuo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -W 2>/dev/null || pwd)"
OUT_DIR=${1:?出力先フォルダを指定してください}
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd -W 2>/dev/null || pwd)"

export MSYS_NO_PATHCONV=1

echo "=== shellcheck ==="
docker run --rm -v "${KIT_ROOT}:/mnt:ro" -w /mnt koalaman/shellcheck:stable \
    -x -S warning setup/*.sh tests/*.sh | tee "$OUT_DIR/shellcheck.txt"

echo "=== container rehearsal ==="
docker run --rm -v "${KIT_ROOT}:/kit:ro" -v "${OUT_DIR}:/out" ubuntu:26.04 \
    bash /kit/tests/container-rehearsal.sh 2>&1 | tee "$OUT_DIR/rehearsal.log"
