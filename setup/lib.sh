#!/usr/bin/env bash
# Shared helpers for the workstation setup scripts. Source it; do not run it.
#
# Environment switches (used by the container rehearsal on the old PC):
#   WORKSTATION_SIMULATE=1   apt installs run with --simulate and installer scripts are only
#                            fetched, never executed. Repository registration still happens.
#   WORKSTATION_CONTAINER=1  skip steps that need systemd, snapd, GPUs or a desktop session.
#   WORKSTATION_STATE_DIR    override the state/log directory.

set -Eeuo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
STATE_DIR="${WORKSTATION_STATE_DIR:-$TARGET_HOME/.local/state/workstation}"
LOG_DIR="$STATE_DIR/logs"
PROGRESS_FILE="$STATE_DIR/progress.tsv"
SIMULATE="${WORKSTATION_SIMULATE:-0}"
IN_CONTAINER="${WORKSTATION_CONTAINER:-0}"
SCRIPT_NAME="$(basename "${0%.sh}")"
DOWNLOAD_DIR=""  # private per run, created by start_script
FAILED_ITEMS=()

log() {
    printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

# True when a command's captured output contains a match. Capturing first avoids
# `cmd | grep -q`, where grep exiting early kills cmd with SIGPIPE and pipefail reports failure.
output_matches() {
    local pattern=$1
    shift
    local out
    out="$("$@" 2>/dev/null)" || true
    grep -q -E -- "$pattern" <<<"$out"
}

in_group() {
    local user=$1 group=$2
    [[ " $(id -nG "$user") " == *" ${group} "* ]]
}

is_root() {
    [ "$(id -u)" -eq 0 ]
}

systemd_running() {
    [ "$IN_CONTAINER" != 1 ] && [ -d /run/systemd/system ]
}

# Give files created by a root script back to the owner of the home directory.
give_to_user() {
    if is_root; then
        chown "$TARGET_USER": "$@"
    fi
}

start_script() {
    local mode=$1  # root | user
    if [ "$mode" = root ] && ! is_root; then
        echo "このスクリプトは管理者権限が必要です。setup/run-as-admin.sh ${SCRIPT_NAME} から実行してください。" >&2
        exit 2
    fi
    if [ "$mode" = user ] && is_root; then
        echo "このスクリプトは sudo を付けずに通常ユーザーで実行してください。" >&2
        exit 2
    fi
    if is_root; then
        # Create the state directories as the owner. Creating them as root would also leave
        # ~/.local and ~/.local/state owned by root and break every later user-level install.
        runuser -u "$TARGET_USER" -- install -d -m 0755 "$STATE_DIR" "$LOG_DIR"
    else
        install -d -m 0755 "$STATE_DIR" "$LOG_DIR"
    fi
    DOWNLOAD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/workstation-${SCRIPT_NAME}.XXXXXX")"
    # apt reads local .deb files as the _apt user.
    chmod 0755 "$DOWNLOAD_DIR"
    trap 'rm -rf "$DOWNLOAD_DIR"' EXIT
    LOG_FILE="$LOG_DIR/${SCRIPT_NAME}-$(date +%Y%m%d-%H%M%S).log"
    touch "$LOG_FILE"
    give_to_user "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    log "開始: ${SCRIPT_NAME}（simulate=${SIMULATE} container=${IN_CONTAINER} user=${TARGET_USER}）"
    record "$SCRIPT_NAME" started ""
}

record() {
    local item=$1 status=$2 detail=${3:-}
    printf '%s\t%s\t%s\t%s\t%s\n' "$(date -Iseconds)" "$SCRIPT_NAME" "$item" "$status" "$detail" >>"$PROGRESS_FILE"
    give_to_user "$PROGRESS_FILE"
}

# Run one item so that its failure is recorded without stopping the remaining items.
# The item runs in a subshell with errexit active (an `if` would silently disable it).
run_item() {
    local item=$1
    shift
    log "── ${item}"
    set +e
    (set -Eeuo pipefail; "$@")
    local rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
        record "$item" ok
        log "   完了: ${item}"
    else
        record "$item" failed "exit ${rc}"
        FAILED_ITEMS+=("$item")
        log "   失敗: ${item}（終了コード ${rc}）"
    fi
}

finish_script() {
    if [ "${#FAILED_ITEMS[@]}" -eq 0 ]; then
        record "$SCRIPT_NAME" finished ok
        log "終了: ${SCRIPT_NAME} はすべて完了しました。ログ: ${LOG_FILE}"
        exit 0
    fi
    record "$SCRIPT_NAME" finished "failed: ${FAILED_ITEMS[*]}"
    log "終了: ${SCRIPT_NAME} で失敗した項目: ${FAILED_ITEMS[*]}。ログ: ${LOG_FILE}"
    exit 1
}

# ---------------------------------------------------------------- apt helpers

APT_DIRTY_MARK="$STATE_DIR/.apt-sources-changed"

pkg_installed() {
    [ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null)" = 'install ok installed' ]
}

apt_refresh() {
    if [ -e "$APT_DIRTY_MARK" ] || [ "${1:-}" = force ]; then
        apt-get update
        rm -f "$APT_DIRTY_MARK"
    fi
}

apt_install() {
    local missing=()
    local pkg
    for pkg in "$@"; do
        pkg_installed "$pkg" || missing+=("$pkg")
    done
    if [ "${#missing[@]}" -eq 0 ]; then
        log "   導入済み: $*"
        return 0
    fi
    apt_refresh
    if [ "$SIMULATE" = 1 ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install --simulate -y "${missing[@]}" >/dev/null
        log "   解決できることを確認: ${missing[*]}"
    else
        DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
    fi
}

# Package names listed one per line; blank lines and # comments are ignored.
read_package_list() {
    grep -v -E '^\s*(#|$)' "$KIT_ROOT/packages/$1" | awk '{print $1}'
}

# Install a signing key. Binary keyrings are dearmored; .asc paths keep the armored text.
install_key() {
    local url=$1 dest=$2
    local tmp
    tmp="$(mktemp)"
    curl -fsSL --retry 3 "$url" -o "$tmp"
    install -d -m 0755 "$(dirname "$dest")"
    case "$dest" in
        *.asc) install -m 0644 "$tmp" "$dest" ;;
        *)
            if grep -q 'BEGIN PGP PUBLIC KEY BLOCK' "$tmp"; then
                gpg --dearmor --yes -o "$dest" "$tmp"
                chmod 0644 "$dest"
            else
                install -m 0644 "$tmp" "$dest"
            fi
            ;;
    esac
    rm -f "$tmp"
}

# Write an apt source file only when its content changes, and remember to refresh apt.
write_apt_source() {
    local dest=$1 content=$2
    if [ -f "$dest" ] && [ "$(cat "$dest")" = "$content" ]; then
        return 0
    fi
    printf '%s\n' "$content" >"$dest"
    chmod 0644 "$dest"
    touch "$APT_DIRTY_MARK"
    log "   リポジトリを登録: ${dest}"
}

download() {
    local url=$1 dest=$2
    curl -fsSL --retry 3 --connect-timeout 20 -o "$dest" "$url"
}

# Newest non-prerelease asset URL whose file name matches an extended regex. Recent releases
# are searched in order because some projects publish platform builds in separate releases.
github_asset_url() {
    local repo=$1 pattern=$2
    local url
    url="$(curl -fsSL --retry 3 "https://api.github.com/repos/${repo}/releases?per_page=15" \
        | jq -r '.[] | select(.draft == false and .prerelease == false) | .assets[].browser_download_url' \
        | grep -E "$pattern" | head -n 1 || true)"
    if [ -z "$url" ]; then
        echo "GitHub ${repo} の最新リリースに ${pattern} に合うファイルがありません" >&2
        return 1
    fi
    printf '%s\n' "$url"
}

install_deb_from_url() {
    local pkg=$1 url=$2
    if pkg_installed "$pkg"; then
        log "   導入済み: ${pkg}"
        return 0
    fi
    local file="$DOWNLOAD_DIR/${pkg}.deb"
    download "$url" "$file"
    # apt runs downloads as the _apt user; keep the file readable for it.
    chmod 0644 "$file"
    local actual
    actual="$(dpkg-deb -f "$file" Package)"
    if [ "$actual" != "$pkg" ]; then
        echo "パッケージ名が想定（${pkg}）と違います: ${actual}。台本の名前を直してください" >&2
        return 1
    fi
    apt_refresh
    if [ "$SIMULATE" = 1 ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install --simulate -y "$file" >/dev/null
        log "   解決できることを確認: ${pkg}（${url}）"
    else
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$file"
    fi
}

# ------------------------------------------------------------- user helpers

# Download an installer script and run it with arguments (fetched only when simulating).
run_installer() {
    local url=$1
    shift
    local file
    file="$(mktemp)"
    download "$url" "$file"
    if [ "$SIMULATE" = 1 ]; then
        log "   取得できることを確認: ${url}"
        rm -f "$file"
        return 0
    fi
    sh "$file" "$@"
    rm -f "$file"
}

# Load the PATH additions the kit manages so freshly installed tools are visible.
load_user_path() {
    local dir
    for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.local/share/fnm" \
        "$HOME/.local/share/fnm/aliases/default/bin" "$HOME/.bun/bin" "$HOME/.duckdb/cli/latest"; do
        case ":$PATH:" in
            *":$dir:"*) ;;
            *) PATH="$dir:$PATH" ;;
        esac
    done
    export PATH
}

# Replace a marked block in a text file (creating the file when needed).
replace_managed_block() {
    local file=$1 marker=$2 content=$3
    local begin="# >>> ${marker} >>>" end="# <<< ${marker} <<<"
    touch "$file"
    local tmp
    tmp="$(mktemp)"
    awk -v b="$begin" -v e="$end" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        !skip { print }
    ' "$file" >"$tmp"
    printf '%s\n%s\n%s\n' "$begin" "$content" "$end" >>"$tmp"
    cat "$tmp" >"$file"
    rm -f "$tmp"
}

# Copy a file or directory, keeping a timestamped backup of anything it replaces.
BACKUP_ROOT="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"
install_with_backup() {
    local src=$1 dest=$2
    if [ -e "$dest" ]; then
        if [ -d "$src" ] && diff -rq "$src" "$dest" >/dev/null 2>&1; then
            return 0
        fi
        if [ -f "$src" ] && cmp -s "$src" "$dest"; then
            return 0
        fi
        local rel=${dest#"$HOME"/}
        install -d "$BACKUP_ROOT/$(dirname "$rel")"
        cp -a "$dest" "$BACKUP_ROOT/$rel"
        log "   既存を退避: ${dest} → ${BACKUP_ROOT}/${rel}"
    fi
    install -d "$(dirname "$dest")"
    if [ -d "$src" ]; then
        mkdir -p "$dest"
        cp -a "$src/." "$dest/"
    else
        cp -a "$src" "$dest"
    fi
}
