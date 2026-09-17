#!/usr/bin/env bash
# Switch the input method framework for this user (both are installed by 10-base.sh).
# Use fcitx5 when Chrome or other apps double Japanese characters under ibus.
#   setup/switch-ime.sh fcitx5   |   setup/switch-ime.sh ibus
# Takes effect after logging out and back in. No password needed.
set -Eeuo pipefail

target=${1:?使い方: switch-ime.sh fcitx5|ibus}
case "$target" in
    fcitx5 | ibus) ;;
    *)
        echo "fcitx5 か ibus を指定してください" >&2
        exit 2
        ;;
esac

im-config -n "$target"
if [ "$target" = fcitx5 ]; then
    mkdir -p "$HOME/.config/autostart"
    if [ -f /usr/share/applications/org.fcitx.Fcitx5.desktop ]; then
        cp /usr/share/applications/org.fcitx.Fcitx5.desktop "$HOME/.config/autostart/"
    fi
    echo "fcitx5 に切り替えました。ログインし直したあと、fcitx5 の設定で Mozc を入力メソッドに加えてください。"
    echo "GNOME では候補ウィンドウの位置がずれることがあります。その場合は GNOME 拡張 Kimpanel を入れると改善します。"
else
    rm -f "$HOME/.config/autostart/org.fcitx.Fcitx5.desktop"
    echo "ibus に戻しました。ログインし直すと有効になります。"
fi
