#!/usr/bin/env bash
# Wait (up to 9 minutes per call, safely under tool timeouts) for an admin script
# started by run-as-admin.sh. Exit codes: 0 done ok, 1 done with failures, 4 still waiting.
set -Eeuo pipefail

STATE_DIR="${WORKSTATION_STATE_DIR:-$HOME/.local/state/workstation}"
name=${1:?使い方: wait-admin.sh <スクリプト名> [待つ秒数]}
limit=${2:-540}
exit_file="$STATE_DIR/${name}.exit"

waited=0
while [ ! -s "$exit_file" ]; do
    if [ "$waited" -ge "$limit" ]; then
        echo "まだ終わっていません（${waited} 秒待ちました）。もう一度 wait-admin.sh ${name} を実行してください。"
        exit 4
    fi
    sleep 5
    waited=$((waited + 5))
done

rc="$(cat "$exit_file")"
latest_log="$(ls -1t "$STATE_DIR/logs/${name}"-*.log 2>/dev/null | head -n 1 || true)"
echo "終了コード: ${rc}"
if [ -n "$latest_log" ]; then
    echo "ログ: ${latest_log}"
    grep -E '失敗|終了:' "$latest_log" | tail -n 20 || true
fi
[ "$rc" -eq 0 ]
