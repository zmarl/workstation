#!/usr/bin/env bash
# Where the setup stands: latest result per item, pending reboot/re-login, admin exit codes.
set -Eeuo pipefail

STATE_DIR="${WORKSTATION_STATE_DIR:-$HOME/.local/state/workstation}"
PROGRESS_FILE="$STATE_DIR/progress.tsv"

if [ ! -f "$PROGRESS_FILE" ]; then
    echo "まだ何も実行していません（最初は setup/run-as-admin.sh 10-base）。"
    exit 0
fi

echo "=== 各項目の最新の結果 ==="
awk -F '\t' '{ key = $2 " / " $3; last[key] = $4 "\t" $1 "\t" $5; order[key] = NR }
    END { for (k in last) print order[k] "\t" k "\t" last[k] }' "$PROGRESS_FILE" \
    | sort -n | cut -f2- | column -t -s $'\t'

echo
echo "=== 管理者スクリプトの終了コード ==="
for f in "$STATE_DIR"/*.exit; do
    [ -e "$f" ] || { echo "なし"; break; }
    printf '%s: %s\n' "$(basename "${f%.exit}")" "$(cat "$f")"
done

echo
[ -e "$STATE_DIR/reboot-required" ] && echo "⚠ 再起動が必要です（ドライバ）。再起動後に 20-gpu をもう一度流し、reboot-required を消します。"
[ -e "$STATE_DIR/relogin-required" ] && echo "⚠ ログインし直しが必要です（グループの変更）。"
exit 0
