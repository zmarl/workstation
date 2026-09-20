#!/usr/bin/env bash
# Switch the input method framework for this user (both are installed by 10-base.sh).
# Use fcitx5 when Chrome or other apps double Japanese characters under ibus.
#   setup/switch-ime.sh fcitx5   |   setup/switch-ime.sh ibus
# Takes effect after logging out and back in. No password needed.
#
# Under fcitx5 the Chrome family has to run as a native Wayland client with the Wayland input
# method enabled, otherwise it talks to XWayland and the two disagree about what was typed.
# The flags go into a per-user copy of the launcher, which apt updates never touch and
# removing the file undoes.
set -Eeuo pipefail

target=${1:?使い方: switch-ime.sh fcitx5|ibus}
case "$target" in
    fcitx5 | ibus) ;;
    *)
        echo "fcitx5 か ibus を指定してください" >&2
        exit 2
        ;;
esac

CHROME_ENTRIES=(google-chrome.desktop com.google.Chrome.desktop)
CHROME_FLAGS="--ozone-platform-hint=auto --enable-wayland-ime"
APPS_DIR="$HOME/.local/share/applications"

write_chrome_override() {
    local entry src dest
    mkdir -p "$APPS_DIR"
    for entry in "${CHROME_ENTRIES[@]}"; do
        src="/usr/share/applications/${entry}"
        dest="${APPS_DIR}/${entry}"
        [ -f "$src" ] || continue
        sed -E "s#^(Exec=[^ ]+)(.*)#\1 ${CHROME_FLAGS}\2#" "$src" >"$dest"
        chmod 0644 "$dest"
        echo "Chrome の起動設定を上書きしました: ${dest}"
    done
    update_desktop_db
}

remove_chrome_override() {
    local entry removed=0
    for entry in "${CHROME_ENTRIES[@]}"; do
        if [ -f "${APPS_DIR}/${entry}" ]; then
            rm -f "${APPS_DIR}/${entry}"
            removed=1
        fi
    done
    if [ "$removed" = 1 ]; then
        echo "Chrome の起動設定の上書きを消しました。"
        update_desktop_db
    fi
}

update_desktop_db() {
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
    fi
}

im-config -n "$target"
if [ "$target" = fcitx5 ]; then
    mkdir -p "$HOME/.config/autostart"
    if [ -f /usr/share/applications/org.fcitx.Fcitx5.desktop ]; then
        cp /usr/share/applications/org.fcitx.Fcitx5.desktop "$HOME/.config/autostart/"
    fi
    write_chrome_override
    echo "fcitx5 に切り替えました。ログインし直したあと、fcitx5 の設定で Mozc を入力メソッドに加えてください。"
    echo "GNOME では候補ウィンドウの位置がずれることがあります。その場合は GNOME 拡張 Kimpanel を入れると改善します。"
    echo "Claude・ChatGPT・Cursor・Discord・Obsidian で文字が入らない場合は、同じ要領で起動設定を上書きします。"
else
    rm -f "$HOME/.config/autostart/org.fcitx.Fcitx5.desktop"
    remove_chrome_override
    echo "ibus に戻しました。ログインし直すと有効になります。"
fi
