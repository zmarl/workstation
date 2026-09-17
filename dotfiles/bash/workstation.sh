# shellcheck shell=bash
# Managed by workstation/setup/60-dotfiles-repos.sh — edits here are overwritten.
# Sourced from ~/.profile (PATH for every login shell, including Claude Code's Bash)
# and from ~/.bashrc (prompt and interactive helpers).

for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.local/share/fnm" \
    "$HOME/.local/share/fnm/aliases/default/bin" "$HOME/.bun/bin" "$HOME/.duckdb/cli/latest"; do
    case ":$PATH:" in
        *":$dir:"*) ;;
        *) [ -d "$dir" ] && PATH="$dir:$PATH" ;;
    esac
done
export PATH

case $- in
    *i*)
        command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
        command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
        command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd --shell bash)"
        ;;
esac
