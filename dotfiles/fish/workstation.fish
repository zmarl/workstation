# Managed by workstation/setup/60-dotfiles-repos.sh — edits here are overwritten.

# User-level tool locations (uv, cargo, fnm default Node, bun, DuckDB)
for dir in $HOME/.local/bin $HOME/.cargo/bin $HOME/.local/share/fnm $HOME/.local/share/fnm/aliases/default/bin $HOME/.bun/bin $HOME/.duckdb/cli/latest
    if test -d $dir
        fish_add_path --global --move $dir
    end
end

if status is-interactive
    if type -q starship
        starship init fish | source
    end
    if type -q zoxide
        zoxide init fish | source
    end
    if type -q fnm
        fnm env --use-on-cd --shell fish | source
    end
end
