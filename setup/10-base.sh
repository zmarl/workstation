#!/usr/bin/env bash
# CHANGES: システム全体のパッケージを最新にし、基本の道具、日本語フォント、日本語入力
# CHANGES: （既定の ibus-mozc と、予備として使わない状態の fcitx5-mozc）、fish と
# CHANGES: コマンドライン道具を入れます。ユーザー・グループ・SSH・sudo の設定は変えません。
# RUN-AS: root（setup/run-as-admin.sh 10-base）
source "$(dirname "$0")/lib.sh"
start_script root

upgrade_system() {
    apt_refresh force
    if [ "$SIMULATE" = 1 ]; then
        apt-get full-upgrade --simulate -y >/dev/null
        log "   更新計画を確認（simulate）"
    else
        DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
    fi
}

install_list() {
    local list=$1
    local pkgs
    mapfile -t pkgs < <(read_package_list "$list")
    apt_install "${pkgs[@]}"
}

run_item "system-upgrade" upgrade_system
run_item "apt-base" install_list apt-base.txt
run_item "apt-cli" install_list apt-cli.txt
run_item "apt-japanese" install_list apt-japanese.txt

finish_script
