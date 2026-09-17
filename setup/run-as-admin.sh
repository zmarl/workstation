#!/usr/bin/env bash
# Hand an admin script to the owner: show what it changes, then open a terminal window
# where the owner types the sudo password. The AI never types passwords.
#
#   setup/run-as-admin.sh 10-base
#   setup/run-as-admin.sh 35-permissions kvm input
#
# Returns right after the window opens. Use setup/wait-admin.sh <name> to wait for the result.
set -Eeuo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${WORKSTATION_STATE_DIR:-$HOME/.local/state/workstation}"

if [ "$#" -lt 1 ]; then
    echo "使い方: run-as-admin.sh <スクリプト名> [引数...]" >&2
    exit 2
fi
name=$1
shift
script="$KIT_ROOT/setup/${name}.sh"
if [ ! -f "$script" ]; then
    echo "見つかりません: ${script}" >&2
    exit 2
fi
if [ "$(id -u)" -eq 0 ]; then
    echo "通常ユーザーで実行してください（sudo はウィンドウの中でオーナーが入力します）" >&2
    exit 2
fi

mkdir -p "$STATE_DIR"
exit_file="$STATE_DIR/${name}.exit"
rm -f "$exit_file"

echo "=== ${name} が変えること ==="
sed -n 's/^# CHANGES: \{0,1\}//p' "$script"
echo "=== 引数: ${*:-なし} ==="

wrapper="$STATE_DIR/admin-${name}.sh"
{
    echo '#!/usr/bin/env bash'
    echo "echo '管理者操作: ${name}'"
    echo "echo 'この内容で実行します。パスワードを入力してください（やめる場合はウィンドウを閉じてください）。'"
    printf 'sudo -- bash %q' "$script"
    printf ' %q' "$@"
    echo
    echo "rc=\$?"
    printf 'echo "$rc" > %q\n' "$exit_file"
    echo 'echo'
    echo 'if [ "$rc" -eq 0 ]; then echo "完了しました。"; else echo "失敗した項目があります（終了コード $rc）。AI がログを確認します。"; fi'
    echo 'read -r -p "Enter でこのウィンドウを閉じます" _'
} >"$wrapper"
chmod 0700 "$wrapper"

if [ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    echo "デスクトップの画面に接続されていません。オーナーに端末で次を実行してもらってください:" >&2
    echo "  bash ${wrapper}" >&2
    exit 3
fi

title="管理者操作: ${name}"
if command -v ptyxis >/dev/null 2>&1; then
    # Ptyxis is the default terminal on Ubuntu 25.10+; its manual prefers "--" over --execute.
    setsid ptyxis --new-window --title="$title" -- bash "$wrapper" >/dev/null 2>&1 &
elif command -v gnome-terminal >/dev/null 2>&1; then
    setsid gnome-terminal --title="$title" -- bash "$wrapper" >/dev/null 2>&1 &
elif command -v wezterm >/dev/null 2>&1; then
    setsid wezterm start --always-new-process -- bash "$wrapper" >/dev/null 2>&1 &
else
    echo "端末アプリが見つかりません。オーナーに端末で次を実行してもらってください:" >&2
    echo "  bash ${wrapper}" >&2
    exit 3
fi
echo "ウィンドウを開きました。オーナーのパスワード入力を待っています（setup/wait-admin.sh ${name}）。"
