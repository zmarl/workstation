#!/usr/bin/env bash
# CHANGES: 自分のホームフォルダの中だけに開発ツールを入れます（パスワード不要）。
# CHANGES: uv と Python 3.12/3.13、Rust、Node.js LTS（fnm）、pnpm・Playwright・ngrok、Bun、
# CHANGES: Codex CLI、DuckDB CLI、yazi、yt-dlp、フォント Moralerspace、fd の別名。
# RUN-AS: 通常ユーザー（bash setup/40-user-tools.sh）
source "$(dirname "$0")/lib.sh"
start_script user
load_user_path

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

DUCKDB_VERSION="${DUCKDB_VERSION:-1.5.5}"
NPM_GLOBALS=(pnpm playwright @expo/ngrok)

tool_uv() {
    if ! have uv; then
        UV_NO_MODIFY_PATH=1 run_installer https://astral.sh/uv/install.sh
    fi
    [ "$SIMULATE" = 1 ] && return 0
    uv python install 3.12 3.13
    uv tool install yt-dlp || uv tool upgrade yt-dlp
}

tool_rust() {
    if ! have rustup; then
        run_installer https://sh.rustup.rs -y --no-modify-path --default-toolchain stable --profile default
    fi
    [ "$SIMULATE" = 1 ] && return 0
    load_user_path
    rustup component add rust-analyzer
}

tool_node() {
    local fnm_dir="$HOME/.local/share/fnm"
    if [ ! -x "$fnm_dir/fnm" ]; then
        if [ "$SIMULATE" = 1 ]; then
            run_installer https://fnm.vercel.app/install
            return 0
        fi
        # The fnm installer is a bash script and needs its own flags.
        local file
        file="$(mktemp)"
        download https://fnm.vercel.app/install "$file"
        bash "$file" --install-dir "$fnm_dir" --skip-shell
        rm -f "$file"
    fi
    [ "$SIMULATE" = 1 ] && return 0
    load_user_path
    fnm install --lts
    fnm default lts-latest
    load_user_path
    npm install -g "${NPM_GLOBALS[@]}"
}

tool_bun() {
    if have bun; then
        return 0
    fi
    if [ "$SIMULATE" = 1 ]; then
        run_installer https://bun.com/install
        return 0
    fi
    local file
    file="$(mktemp)"
    download https://bun.com/install "$file"
    BUN_INSTALL="$HOME/.bun" bash "$file"
    rm -f "$file"
}

tool_codex() {
    if have codex; then
        log "   Codex CLI は導入済み（$(codex --version 2>/dev/null || echo 版不明)）"
        return 0
    fi
    CODEX_NON_INTERACTIVE=1 run_installer https://chatgpt.com/codex/install.sh
}

tool_duckdb() {
    if [ -x "$HOME/.duckdb/cli/${DUCKDB_VERSION}/duckdb" ]; then
        return 0
    fi
    if [ "$SIMULATE" = 1 ]; then
        curl -fsI "https://install.duckdb.org/v${DUCKDB_VERSION}/duckdb_cli-linux-amd64.zip" >/dev/null
        log "   取得できることを確認: DuckDB ${DUCKDB_VERSION}"
        return 0
    fi
    local file
    file="$(mktemp)"
    download https://install.duckdb.org "$file"
    DUCKDB_VERSION="$DUCKDB_VERSION" bash "$file"
    rm -f "$file"
}

tool_yazi() {
    if have yazi; then
        return 0
    fi
    local url tmp
    url="$(github_asset_url sxyazi/yazi '/yazi-x86_64-unknown-linux-gnu\.zip$')"
    tmp="$(mktemp -d)"
    download "$url" "$tmp/yazi.zip"
    if [ "$SIMULATE" = 1 ]; then
        log "   取得できることを確認: ${url}"
        rm -rf "$tmp"
        return 0
    fi
    unzip -q "$tmp/yazi.zip" -d "$tmp"
    install -m 0755 "$tmp"/yazi-x86_64-unknown-linux-gnu/yazi "$tmp"/yazi-x86_64-unknown-linux-gnu/ya "$LOCAL_BIN/"
    rm -rf "$tmp"
}

tool_fonts() {
    local font_dir="$HOME/.local/share/fonts/Moralerspace"
    if output_matches 'Moralerspace Neon' fc-list : family; then
        return 0
    fi
    local url tmp
    url="$(github_asset_url yuru7/moralerspace '/Moralerspace_v[0-9.]+\.zip$')"
    tmp="$(mktemp -d)"
    download "$url" "$tmp/font.zip"
    if [ "$SIMULATE" = 1 ]; then
        log "   取得できることを確認: ${url}"
        rm -rf "$tmp"
        return 0
    fi
    mkdir -p "$font_dir"
    unzip -q -o "$tmp/font.zip" -d "$tmp"
    find "$tmp" -name '*.ttf' -exec install -m 0644 {} "$font_dir/" \;
    rm -rf "$tmp"
    fc-cache -f "$font_dir"
    output_matches 'Moralerspace Neon' fc-list : family
}

tool_fd_alias() {
    # Ubuntu names the fd binary fdfind.
    if [ -x /usr/bin/fdfind ] && [ ! -e "$LOCAL_BIN/fd" ]; then
        ln -s /usr/bin/fdfind "$LOCAL_BIN/fd"
    fi
}

run_item "uv-python" tool_uv
run_item "rust" tool_rust
run_item "node" tool_node
run_item "bun" tool_bun
run_item "codex-cli" tool_codex
run_item "duckdb" tool_duckdb
run_item "yazi" tool_yazi
run_item "font-moralerspace" tool_fonts
run_item "fd-alias" tool_fd_alias

finish_script
