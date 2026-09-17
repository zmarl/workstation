#!/usr/bin/env bash
# CHANGES: Windows から持ち出した AI の設定を、自分のホームフォルダに戻します（パスワード不要）。
# CHANGES: Claude Code … ルール・スキル・settings.json・計画ファイル・投資アプリのメモリ・プラグイン・MCP の雛形
# CHANGES: Codex … AGENTS.md・config.toml（Linux のパスへ置換）・役割定義・規則・スキル・メモリ・計画ファイル
# CHANGES: 置き換える前の既存ファイルは ~/.local/state/workstation/backups/ に退避します。
# RUN-AS: 通常ユーザー（bash setup/50-ai-config.sh [--investment-path ~/dev/Investment]）
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

SRC="$KIT_ROOT/ai-config"

# Claude Code names a project's folder after its absolute path with every
# character other than letters and digits replaced by "-" (D:\Dev\Investment -> D--Dev-Investment).
claude_project_slug() {
    printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'
}

claude_rules_skills_settings() {
    install_with_backup "$SRC/claude/rules" "$HOME/.claude/rules"
    install_with_backup "$SRC/claude/skills" "$HOME/.claude/skills"
    install_with_backup "$SRC/claude/plans" "$HOME/.claude/plans"
    install_with_backup "$SRC/claude/settings.json" "$HOME/.claude/settings.json"
}

claude_memory() {
    local slug
    slug="$(claude_project_slug "$INVESTMENT_PATH")"
    install_with_backup "$SRC/claude/memory/investment" "$HOME/.claude/projects/${slug}/memory"
    log "   メモリの置き場所: ~/.claude/projects/${slug}/memory（${INVESTMENT_PATH} 用）"
}

claude_plugins() {
    if ! have claude; then
        echo "claude コマンドが見つかりません（段階 1 で入れる Claude Code が必要です）" >&2
        return 1
    fi
    local name repo
    while IFS=$'\t' read -r name repo; do
        # </dev/null keeps claude from consuming the list this loop reads.
        if output_matches "$name" claude plugin marketplace list </dev/null; then
            continue
        fi
        claude plugin marketplace add "$repo" </dev/null
    done < <(jq -r '.marketplaces | to_entries[] | "\(.key)\t\(.value)"' "$SRC/claude/plugins.json")
    local plugin
    while read -r plugin; do
        claude plugin install "$plugin" </dev/null || {
            echo "プラグイン ${plugin} を入れられませんでした" >&2
            return 1
        }
    done < <(jq -r '.plugins[]' "$SRC/claude/plugins.json")
}

claude_mcp_template() {
    # Tokens are never carried. The template records which servers existed on Windows;
    # the owner decides whether to add each one again (Notion is retired in the Investment app).
    install -d "$HOME/.claude"
    install -m 0600 "$SRC/claude/mcp.template.json" "$HOME/.claude/mcp.template-from-windows.json"
    log "   MCP の雛形を ~/.claude/mcp.template-from-windows.json に置きました（トークンは含みません）"
}

codex_config() {
    local codex="$HOME/.codex"
    install -d "$codex"
    install_with_backup "$SRC/codex/AGENTS.md" "$codex/AGENTS.md"
    install_with_backup "$SRC/codex/agents" "$codex/agents"
    install_with_backup "$SRC/codex/skills" "$codex/skills"
    install_with_backup "$SRC/codex/plans" "$codex/plans"
    install -d "$codex/rules"
    install_with_backup "$SRC/codex/rules/default.rules" "$codex/rules/default.rules"
    install_with_backup "$SRC/codex/rules/host-executables.linux.rules" "$codex/rules/host-executables.rules"

    local rendered
    rendered="$(mktemp)"
    sed -e "s#__INVESTMENT_PATH__#${INVESTMENT_PATH}#g" -e "s#__HOME__#${HOME}#g" \
        "$SRC/codex/config.linux.toml" >"$rendered"
    install_with_backup "$rendered" "$codex/config.toml"
    rm -f "$rendered"
}

codex_memories() {
    install_with_backup "$SRC/codex/memories" "$HOME/.codex/memories"
}

run_item "claude-rules-skills-settings" claude_rules_skills_settings
run_item "claude-memory" claude_memory
run_item "claude-mcp-template" claude_mcp_template
run_item "codex-config" codex_config
run_item "codex-memories" codex_memories
if [ "$IN_CONTAINER" = 1 ]; then
    log "コンテナではプラグインの導入（Claude へのログインが必要）を省略"
else
    run_item "claude-plugins" claude_plugins
fi

finish_script
