#!/usr/bin/env bash
# CHANGES: 音声入力 Handy を GNOME + Wayland で呼び出せるようにします。GNOME のカスタム
# CHANGES: ショートカット（既定は無変換キー）に Handy の切り替えコマンドを割り当て、
# CHANGES: ログイン時に Handy が裏で起動するよう ~/.config/autostart に登録します。
# CHANGES: 変えるのはこのユーザーの設定だけで、管理者権限は要りません。
# RUN-AS: 通常ユーザー（bash setup/70-handy-wayland.sh [--key Muhenkan]）
source "$(dirname "$0")/lib.sh"

# Wayland compositors do not deliver an application's own global hotkey while another window
# has focus, so Handy documents a desktop-level shortcut instead (handy.computer/docs/cli).
HANDY_KEY="${HANDY_KEY:-Muhenkan}"
SHORTCUT_NAME="Handy"
KEYS_SCHEMA=org.gnome.settings-daemon.plugins.media-keys
KEY_SCHEMA="${KEYS_SCHEMA}.custom-keybinding"
KEY_PATH_BASE=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings

while [ "$#" -gt 0 ]; do
    case "$1" in
        --key)
            HANDY_KEY=$2
            shift 2
            ;;
        *)
            echo "不明な引数: $1" >&2
            exit 2
            ;;
    esac
done

start_script user

usable() {
    if [ "$IN_CONTAINER" = 1 ]; then
        log "   コンテナなので設定しません"
        return 1
    fi
    if ! have handy; then
        log "   Handy が入っていません（30-apps.sh handy）"
        return 1
    fi
    if ! have gsettings || ! gsettings writable "$KEYS_SCHEMA" custom-keybindings >/dev/null 2>&1; then
        log "   GNOME の設定が読めないので、ショートカットの登録は省略します"
        return 1
    fi
    return 0
}

# The list is a GVariant array of paths; each entry carries its own name/command/binding.
existing_path() {
    local list entry name
    list="$(gsettings get "$KEYS_SCHEMA" custom-keybindings)"
    for entry in $(printf '%s' "$list" | tr -d "[]' " | tr ',' '\n'); do
        [ -n "$entry" ] || continue
        name="$(gsettings get "${KEY_SCHEMA}:${entry}" name 2>/dev/null | tr -d "'")"
        if [ "$name" = "$SHORTCUT_NAME" ]; then
            printf '%s' "$entry"
            return 0
        fi
    done
    return 1
}

free_path() {
    local list i path
    list="$(gsettings get "$KEYS_SCHEMA" custom-keybindings)"
    for i in $(seq 0 99); do
        path="${KEY_PATH_BASE}/custom${i}/"
        case "$list" in
            *"$path"*) ;;
            *)
                printf '%s' "$path"
                return 0
                ;;
        esac
    done
    echo "空いているショートカットの枠が見つかりません" >&2
    return 1
}

add_to_list() {
    local path=$1 list
    list="$(gsettings get "$KEYS_SCHEMA" custom-keybindings)"
    case "$list" in
        *"$path"*) return 0 ;;
    esac
    if [ "$list" = "@as []" ] || [ "$list" = "[]" ]; then
        gsettings set "$KEYS_SCHEMA" custom-keybindings "['${path}']"
    else
        gsettings set "$KEYS_SCHEMA" custom-keybindings "${list%]}, '${path}']"
    fi
}

shortcut() {
    usable || return 0
    local path
    if path="$(existing_path)"; then
        log "   登録済みのショートカットを更新します: ${path}"
    else
        path="$(free_path)"
        add_to_list "$path"
        log "   ショートカットを作りました: ${path}"
    fi
    gsettings set "${KEY_SCHEMA}:${path}" name "$SHORTCUT_NAME"
    gsettings set "${KEY_SCHEMA}:${path}" command "$(command -v handy) --toggle-transcription"
    gsettings set "${KEY_SCHEMA}:${path}" binding "$HANDY_KEY"
    log "   ${HANDY_KEY} キーで Handy の録音を切り替えます"
}

# The shortcut talks to a running instance, so Handy has to be up before the key is pressed.
autostart() {
    usable || return 0
    local src=/usr/share/applications/Handy.desktop
    local dest="$HOME/.config/autostart/Handy.desktop"
    if [ ! -f "$src" ]; then
        log "   Handy.desktop が見つからないので自動起動は登録しません"
        return 0
    fi
    install -d -m 0755 "$HOME/.config/autostart"
    sed -E 's#^(Exec=[^ ]+)( .*)?$#\1 --start-hidden#' "$src" >"${dest}.new"
    if [ -f "$dest" ] && cmp -s "$dest" "${dest}.new"; then
        rm -f "${dest}.new"
        log "   自動起動は登録済み"
        return 0
    fi
    mv "${dest}.new" "$dest"
    chmod 0644 "$dest"
    log "   ログイン時に Handy を裏で起動します: ${dest}"
}

# ydotool is how Handy types the transcript into other windows on Wayland.
check_prerequisites() {
    usable || return 0
    if ! in_group "$(id -un)" input; then
        log "   input グループに未参加です。35-permissions.sh input とログインし直しの後で有効になります"
    fi
    if have systemctl && ! systemctl --user is-active ydotool.service >/dev/null 2>&1; then
        log "   ydotool の常駐が動いていません。60-dotfiles-repos.sh で有効にします"
    fi
}

run_item "handy-shortcut" shortcut
run_item "handy-autostart" autostart
run_item "handy-prerequisites" check_prerequisites

finish_script
