#!/usr/bin/env bash
# CHANGES: NVIDIA のオープン版ドライバ（既定は下の NVIDIA_DRIVER_PACKAGE）を入れ、
# CHANGES: GPU の常駐設定（nvidia-persistenced）を有効にします。
# CHANGES: ドライバを入れた・入れ替えた場合は再起動が必要です（再起動はオーナーが行います）。
# RUN-AS: root（setup/run-as-admin.sh 20-gpu）
source "$(dirname "$0")/lib.sh"
start_script root

# Blackwell (RTX 5070 Ti / RTX PRO 5000) needs the open kernel modules. The series is
# chosen to satisfy the CUDA version ODR-0044 plans (see docs/decisions.md).
NVIDIA_DRIVER_PACKAGE="${NVIDIA_DRIVER_PACKAGE:-nvidia-driver-610-open}"
NVIDIA_MIN_VERSION="${NVIDIA_MIN_VERSION:-610}"
REBOOT_MARK="$STATE_DIR/reboot-required"

detect_gpus() {
    lspci -nn | grep -i -E 'vga|3d controller' | grep -i nvidia || {
        if [ "$IN_CONTAINER" = 1 ]; then
            log "   コンテナなので GPU の検出は省略"
            return 0
        fi
        echo "NVIDIA の GPU が見つかりません" >&2
        return 1
    }
}

current_driver_major() {
    if have nvidia-smi && nvidia-smi --query-gpu=driver_version --format=csv,noheader >/dev/null 2>&1; then
        nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1 | cut -d. -f1
    fi
}

install_driver() {
    local major
    major="$(current_driver_major || true)"
    if [ -n "$major" ] && [ "$major" -ge "$NVIDIA_MIN_VERSION" ] \
        && output_matches '^nvidia-driver-[0-9]+-open$' dpkg-query -W -f='${Package}\n' 'nvidia-driver-*-open'; then
        log "   動作中のドライバ ${major} 系（オープン版）は要件を満たすので入れ替えません"
        return 0
    fi
    if pkg_installed "$NVIDIA_DRIVER_PACKAGE"; then
        log "   ${NVIDIA_DRIVER_PACKAGE} は導入済み。反映には再起動が必要です"
        touch "$REBOOT_MARK"
        give_to_user "$REBOOT_MARK"
        return 0
    fi
    apt_install "$NVIDIA_DRIVER_PACKAGE"
    if [ "$SIMULATE" != 1 ]; then
        touch "$REBOOT_MARK"
        give_to_user "$REBOOT_MARK"
        log "   ${NVIDIA_DRIVER_PACKAGE} を入れました。再起動してください"
    fi
}

enable_persistence() {
    if ! systemd_running; then
        log "   systemd が無い環境なので常駐設定は省略"
        return 0
    fi
    if ! systemctl cat nvidia-persistenced.service >/dev/null 2>&1; then
        log "   nvidia-persistenced はドライバ導入後の再起動のあとで有効にします（再実行してください）"
        return 0
    fi
    # On 26.04 the unit is static (no [Install] section), so it can only be started, and
    # asking systemctl to enable it prints a long notice that looks like a failure.
    local state
    state="$(systemctl is-enabled nvidia-persistenced.service 2>/dev/null || true)"
    if [ "$state" = static ]; then
        systemctl start nvidia-persistenced.service
        log "   nvidia-persistenced は静的ユニットのため起動のみ行いました"
        return 0
    fi
    systemctl enable --now nvidia-persistenced.service || systemctl enable nvidia-persistenced.service
}

run_item "detect-gpus" detect_gpus
run_item "nvidia-driver" install_driver
run_item "nvidia-persistenced" enable_persistence

finish_script
