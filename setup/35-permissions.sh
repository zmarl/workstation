#!/usr/bin/env bash
# CHANGES: 引数で指定したものだけを変えます（オーナーが項目ごとに了承したものだけを渡す）。
# CHANGES:   kvm    … Claude アプリの Cowork が仮想マシンを使えるよう、kvm グループに入れ vhost_vsock を毎回読み込む
# CHANGES:   docker … sudo なしで Docker を使えるよう docker グループに入れる（管理者と同等の強さになる）
# CHANGES:   input  … 音声入力（Handy）が文字を打ち込めるよう input グループに入れる（キー入力の注入を許す）
# CHANGES:   ssh    … SSH サーバーを入れる。公開鍵でのみ入れ、パスワードと root のログインは禁止
# CHANGES: グループの変更は、いったんログアウトして入り直すまで効きません。
# RUN-AS: root（setup/run-as-admin.sh 35-permissions kvm docker input ssh）
source "$(dirname "$0")/lib.sh"

if [ "$#" -eq 0 ]; then
    echo "使い方: 35-permissions.sh [kvm] [docker] [input] [ssh]（了承済みの項目だけを指定）" >&2
    exit 2
fi

start_script root

add_to_group() {
    local group=$1
    if ! getent group "$group" >/dev/null; then
        if [ "$IN_CONTAINER" = 1 ]; then
            log "   最小構成のコンテナには ${group} グループが無いため省略"
            return 0
        fi
        echo "グループ ${group} がありません（docker は 30-apps の Docker 導入で作られます。kvm と input は Ubuntu の標準で存在するはずです）" >&2
        return 1
    fi
    if in_group "$TARGET_USER" "$group"; then
        log "   ${TARGET_USER} は ${group} に参加済み"
        return 0
    fi
    usermod -aG "$group" "$TARGET_USER"
    touch "$STATE_DIR/relogin-required"
    give_to_user "$STATE_DIR/relogin-required"
    log "   ${TARGET_USER} を ${group} に追加（ログインし直すと有効）"
}

permit_kvm() {
    add_to_group kvm
    local conf=/etc/modules-load.d/vhost_vsock.conf
    if [ "$(cat "$conf" 2>/dev/null)" != vhost_vsock ]; then
        echo vhost_vsock >"$conf"
    fi
    if [ "$IN_CONTAINER" != 1 ]; then
        modprobe vhost_vsock
    fi
}

permit_docker() {
    add_to_group docker
}

permit_input() {
    add_to_group input
}

permit_ssh() {
    apt_install openssh-server
    local conf=/etc/ssh/sshd_config.d/50-workstation.conf
    local content
    content="$(printf '%s\n' \
        '# Managed by workstation/setup/35-permissions.sh' \
        'PasswordAuthentication no' \
        'KbdInteractiveAuthentication no' \
        'PermitRootLogin no')"
    if [ "$SIMULATE" = 1 ]; then
        log "   sshd の設定は simulate では書きません"
        return 0
    fi
    install -d -m 0755 "$(dirname "$conf")"
    if [ "$(cat "$conf" 2>/dev/null)" != "$content" ]; then
        printf '%s\n' "$content" >"$conf"
    fi
    sshd -t
    if systemd_running; then
        systemctl enable --now ssh.socket 2>/dev/null || systemctl enable --now ssh.service
        systemctl restart ssh.service 2>/dev/null || true
    fi
    log "   公開鍵を ~/.ssh/authorized_keys に置くまで、SSH ではログインできません"
}

for choice in "$@"; do
    case "$choice" in
        kvm) run_item "permit-kvm" permit_kvm ;;
        docker) run_item "permit-docker" permit_docker ;;
        input) run_item "permit-input" permit_input ;;
        ssh) run_item "permit-ssh" permit_ssh ;;
        *)
            log "不明な項目: ${choice}"
            FAILED_ITEMS+=("unknown-${choice}")
            ;;
    esac
done

finish_script
