#!/usr/bin/env bash
# CHANGES: 端末まわりの設定（WezTerm・starship・fish・bash の PATH）と Git の全体設定を置き、
# CHANGES: GitHub から作業用リポジトリ（Investment）を取得します。
# CHANGES: Git の設定は名前・メール・既定ブランチ・改行（Linux 向けに input）・git-lfs だけを変えます。
# RUN-AS: 通常ユーザー（bash setup/60-dotfiles-repos.sh [--dev-dir ~/dev]）
source "$(dirname "$0")/lib.sh"

DEV_DIR="$HOME/dev"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --dev-dir)
            DEV_DIR=$2
            shift 2
            ;;
        *)
            echo "不明な引数: $1" >&2
            exit 2
            ;;
    esac
done

start_script user
load_user_path

DOT="$KIT_ROOT/dotfiles"

terminal_configs() {
    install_with_backup "$DOT/wezterm" "$HOME/.config/wezterm"
    install_with_backup "$DOT/starship.toml" "$HOME/.config/starship.toml"
    install_with_backup "$DOT/fish/workstation.fish" "$HOME/.config/fish/conf.d/workstation.fish"
    install_with_backup "$DOT/bash/workstation.sh" "$HOME/.config/workstation/shell.sh"
    local line='[ -f "$HOME/.config/workstation/shell.sh" ] && . "$HOME/.config/workstation/shell.sh"'
    replace_managed_block "$HOME/.profile" workstation "$line"
    replace_managed_block "$HOME/.bashrc" workstation "$line"
}

git_global_config() {
    git config --global user.name zmarl
    git config --global user.email 168331371+zmarl@users.noreply.github.com
    git config --global init.defaultBranch main
    git config --global core.autocrlf input
    if have git-lfs; then
        git lfs install --skip-repo
    fi
}

clone_repo() {
    local repo=$1 dest=$2
    if [ -d "$dest/.git" ]; then
        log "   取得済み: ${dest}"
        git -C "$dest" fetch --prune origin
        return 0
    fi
    if ! gh auth status >/dev/null 2>&1; then
        echo "GitHub にログインしていません（gh auth login を先に）" >&2
        return 1
    fi
    mkdir -p "$(dirname "$dest")"
    gh repo clone "$repo" "$dest"
}

repos() {
    if have gh && gh auth status >/dev/null 2>&1; then
        gh auth setup-git
    fi
    # tools (Multi-Agent-Orchestration) and codex-pet were dropped on 2026-09-20: the owner
    # does not need them and neither exists on GitHub.
    clone_repo zmarl/Investment "$DEV_DIR/Investment"
}

ydotool_service() {
    if [ "$IN_CONTAINER" = 1 ] || ! have ydotoold; then
        log "   ydotool の常駐は対象外（コンテナ、または未導入）"
        return 0
    fi
    if ! in_group "$(id -un)" input; then
        log "   input グループに未参加のため、ydotool の常駐は 35-permissions.sh input とログインし直しの後で"
        return 0
    fi
    systemctl --user enable --now ydotool.service
}

run_item "terminal-configs" terminal_configs
run_item "git-global-config" git_global_config
if [ "$IN_CONTAINER" = 1 ]; then
    log "コンテナでは GitHub からの取得を省略"
else
    run_item "repos" repos
fi
run_item "ydotool-service" ydotool_service

finish_script
