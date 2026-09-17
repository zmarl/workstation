#!/usr/bin/env bash
# Verification table for the whole setup. Changes nothing except writing the result files
# ~/.local/state/workstation/verify-latest.tsv and gpu-inventory.txt.
# RUN-AS: 通常ユーザー（bash setup/90-verify.sh [--investment-path ~/dev/Investment]）
# Exit code: 0 when no automatic check failed (manual checks are listed for the owner).
source "$(dirname "$0")/lib.sh"

INVESTMENT_PATH="$HOME/dev/Investment"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --investment-path)
            INVESTMENT_PATH=$2
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

RESULT_FILE="$STATE_DIR/verify-latest.tsv"
: >"$RESULT_FILE"
FAIL_COUNT=0

result() {
    local status=$1 item=$2 detail=${3:-}
    printf '%s\t%s\t%s\n' "$status" "$item" "$detail" >>"$RESULT_FILE"
    [ "$status" = FAIL ] && FAIL_COUNT=$((FAIL_COUNT + 1))
    return 0
}

check_cmd() {
    local item=$1
    shift
    local out rc=0
    # Capture everything first; piping into head could kill the command with SIGPIPE.
    out="$("$@" 2>&1)" || rc=$?
    out=${out%%$'\n'*}
    if [ "$rc" -eq 0 ]; then
        result PASS "$item" "$out"
    else
        result FAIL "$item" "${out:-実行できません}"
    fi
}

check_present() {
    local item=$1 cmd=$2
    if have "$cmd"; then
        result PASS "$item" "$(command -v "$cmd")"
    else
        result FAIL "$item" "見つかりません"
    fi
}

check_pkg() {
    local pkg
    for pkg in "$@"; do
        if pkg_installed "$pkg"; then
            result PASS "package ${pkg}" "$(dpkg-query -W -f='${Version}' "$pkg")"
        else
            result FAIL "package ${pkg}" "未導入"
        fi
    done
}

# ---------------------------------------------------------------- system
. /etc/os-release
if [ "${VERSION_ID}" = 26.04 ]; then
    result PASS "Ubuntu 26.04" "$PRETTY_NAME"
else
    result FAIL "Ubuntu 26.04" "$PRETTY_NAME"
fi

if [ "$IN_CONTAINER" = 1 ]; then
    result SKIP "GPU 2 枚（5070 Ti と PRO 5000）" "コンテナ"
    result SKIP "Docker の中から GPU" "コンテナ"
else
    if have nvidia-smi && nvidia-smi -L >"$STATE_DIR/gpu-inventory.txt" 2>&1; then
        nvidia-smi --query-gpu=index,name,uuid,driver_version,memory.total,ecc.mode.current \
            --format=csv >>"$STATE_DIR/gpu-inventory.txt" 2>&1 || true
        if grep -q '5070 Ti' "$STATE_DIR/gpu-inventory.txt" && grep -q 'PRO 5000' "$STATE_DIR/gpu-inventory.txt"; then
            result PASS "GPU 2 枚（5070 Ti と PRO 5000）" "$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1) / 控え: gpu-inventory.txt"
        else
            result FAIL "GPU 2 枚（5070 Ti と PRO 5000）" "$(tr '\n' ' ' <"$STATE_DIR/gpu-inventory.txt")"
        fi
    else
        result FAIL "GPU 2 枚（5070 Ti と PRO 5000）" "nvidia-smi が動きません"
    fi
    if docker info >/dev/null 2>&1; then
        check_cmd "Docker の中から GPU" docker run --rm --gpus all ubuntu:26.04 nvidia-smi -L
    else
        result MANUAL "Docker の中から GPU" "docker グループ未参加。了承後 35-permissions.sh docker → ログインし直し → 再実行"
    fi
fi
[ -e "$STATE_DIR/reboot-required" ] && result FAIL "再起動待ち" "ドライバ導入後に再起動し、20-gpu を再実行してから消してください"

# ---------------------------------------------------------- command-line tools
check_cmd "git" git --version
check_cmd "git-lfs" git lfs version
check_cmd "gh" gh --version
if [ "$IN_CONTAINER" = 1 ]; then
    result SKIP "GitHub ログイン" "コンテナ"
else
    check_cmd "GitHub ログイン" gh auth status
fi
check_cmd "uv" uv --version
check_cmd "Python 3.12（uv）" uv run --no-project --python 3.12 python --version
check_cmd "Node.js" node --version
check_cmd "pnpm" pnpm --version
check_cmd "Playwright" playwright --version
check_cmd "Bun" bun --version
check_cmd "Rust" cargo --version
check_cmd "rust-analyzer" rust-analyzer --version
check_cmd "Codex CLI" codex --version
check_cmd "DuckDB CLI" duckdb --version
check_cmd "yt-dlp" yt-dlp --version
for tool in rg fd fzf jq nvim lazygit yazi zoxide starship fish ffmpeg magick; do
    check_cmd "$tool" "$tool" --version
done
check_present "7-Zip" 7zz
check_present "Poppler（pdftotext）" pdftotext
if [ "$IN_CONTAINER" = 1 ]; then
    result SKIP "Claude Code" "コンテナ（段階 1 でオーナーが導入）"
else
    check_cmd "Claude Code" claude --version
fi
if output_matches 'Moralerspace Neon' fc-list : family; then
    result PASS "フォント Moralerspace Neon" ""
else
    result FAIL "フォント Moralerspace Neon" "fc-list に出ません"
fi

# ------------------------------------------------------------------- apps
check_pkg google-chrome-stable claude-desktop chatgpt cursor wezterm-nightly discord obsidian \
    opencode handy solaar gsmartcontrol cpu-x ydotool coolercontrol lact \
    docker-ce nvidia-container-toolkit
if [ "$IN_CONTAINER" = 1 ]; then
    result SKIP "Thunderbird（snap）" "コンテナ"
elif snap list thunderbird >/dev/null 2>&1; then
    result PASS "Thunderbird（snap）" "$(snap list thunderbird | awk 'NR==2 {print $2}')"
else
    result FAIL "Thunderbird（snap）" "未導入"
fi
if [ "$(apt-cache policy 2>/dev/null | grep -c 'dl.google.com/linux/chrome')" -ge 1 ]; then
    result PASS "Chrome の更新リポジトリ" ""
else
    result FAIL "Chrome の更新リポジトリ" "登録されていません"
fi
if [ "$(apt-cache policy 2>/dev/null | grep -c 'codex-app-prod')" -ge 1 ]; then
    result PASS "ChatGPT の更新リポジトリ" ""
else
    result FAIL "ChatGPT の更新リポジトリ" "登録されていません"
fi

# -------------------------------------------------------------- AI settings
slug="$(printf '%s' "$INVESTMENT_PATH" | sed 's/[^A-Za-z0-9]/-/g')"
[ -f "$HOME/.claude/rules/core-behavior.md" ] && result PASS "Claude のルール" "" || result FAIL "Claude のルール" "$HOME/.claude/rules がありません"
if [ -f "$HOME/.claude/projects/${slug}/memory/MEMORY.md" ]; then
    result PASS "Claude のメモリ（新しいパス）" "$HOME/.claude/projects/${slug}/memory"
else
    result FAIL "Claude のメモリ（新しいパス）" "$HOME/.claude/projects/${slug}/memory/MEMORY.md がありません"
fi
[ -f "$HOME/.codex/AGENTS.md" ] && result PASS "Codex の AGENTS.md" "" || result FAIL "Codex の AGENTS.md" "ありません"
if [ -f "$HOME/.codex/config.toml" ] && ! grep -q -E '__(INVESTMENT_PATH|HOME)__|C:\\\\' "$HOME/.codex/config.toml"; then
    result PASS "Codex の config.toml（Linux のパス）" ""
else
    result FAIL "Codex の config.toml（Linux のパス）" "未配置か、置換漏れ・Windows のパスが残っています"
fi
[ -f "$HOME/.codex/memories/MEMORY.md" ] && result PASS "Codex のメモリ" "" || result FAIL "Codex のメモリ" "ありません"

# ------------------------------------------------------------------ repos
if [ "$IN_CONTAINER" = 1 ]; then
    result SKIP "Investment リポジトリ" "コンテナ"
elif [ -d "$INVESTMENT_PATH/.git" ]; then
    git -C "$INVESTMENT_PATH" fetch --quiet origin main || true
    if [ "$(git -C "$INVESTMENT_PATH" rev-parse HEAD)" = "$(git -C "$INVESTMENT_PATH" rev-parse origin/main)" ]; then
        result PASS "Investment リポジトリ" "main と一致 $(git -C "$INVESTMENT_PATH" rev-parse --short HEAD)"
    else
        result FAIL "Investment リポジトリ" "HEAD が origin/main と違います"
    fi
else
    result FAIL "Investment リポジトリ" "${INVESTMENT_PATH} にありません"
fi

# ---------------------------------------------------------- owner checks
result MANUAL "日本語入力" "Chrome と Claude アプリで『日本語入力テスト』と打ち、二重にならないか（なる場合は switch-ime.sh fcitx5）"
result MANUAL "音声入力" "Handy で日本語を話し、エディタに文字が入るか（モデルは Whisper を選ぶ）"
result MANUAL "オーディオ" "MOTU から音が出るか、HyperX QuadCast S（と MOTU）のマイクが入るか（設定 → サウンド）"
result MANUAL "Discord" "ログイン、通話、画面共有ができるか"
result MANUAL "Chrome の同期" "ブックマーク・パスワード・拡張機能（LINE を含む）が戻ったか"
result MANUAL "各アプリのログイン" "Claude アプリ・ChatGPT・Cursor・Obsidian・Thunderbird・OpenCode"
result MANUAL "Claude のメモリ" "Claude Code で投資アプリのフォルダを開き、過去のメモリの内容を尋ねて答えられるか"

echo
column -t -s $'\t' "$RESULT_FILE"
echo
echo "自動確認の失敗: ${FAIL_COUNT} 件（結果: ${RESULT_FILE}）"
record verify "$([ "$FAIL_COUNT" -eq 0 ] && echo ok || echo failed)" "fail=${FAIL_COUNT}"
[ "$FAIL_COUNT" -eq 0 ]
