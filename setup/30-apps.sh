#!/usr/bin/env bash
# CHANGES: 配布元の公式 apt リポジトリを登録し（GitHub CLI・Claude アプリ・Cursor・WezTerm・
# CHANGES: Docker・NVIDIA Container Toolkit・CoolerControl。Chrome と ChatGPT は公式 .deb が自分で登録）、
# CHANGES: 日常アプリ（Chrome・Claude・ChatGPT・Discord・Cursor・Obsidian・OpenCode・LM Studio・Thunderbird）、
# CHANGES: 音声入力 Handy、周辺機器・監視の代替（Solaar・CoolerControl・LACT・GSmartControl・CPU-X）、
# CHANGES: Docker Engine と GPU 用のコンテナ設定を入れます。グループへの追加は行いません（35-permissions.sh）。
# RUN-AS: root（setup/run-as-admin.sh 30-apps）。項目を絞るときは引数に項目名（例: chrome discord）
source "$(dirname "$0")/lib.sh"
start_script root

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"

# ------------------------------------------------------------------ apt repositories

app_gh() {
    install_key https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        /etc/apt/keyrings/githubcli-archive-keyring.gpg
    write_apt_source /etc/apt/sources.list.d/github-cli.list \
        "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"
    # Ubuntu ships an older gh in universe/ESM, and the ESM pocket outranks third-party
    # repositories by default. Prefer the upstream build the kit is written against.
    write_apt_source /etc/apt/preferences.d/github-cli.pref \
        "Package: gh
Pin: origin cli.github.com
Pin-Priority: 600"
    apt_install gh
    # A gh already installed from Ubuntu's pocket is not replaced by apt_install, so move it
    # to the pinned upstream build when the candidate differs from what is installed.
    if [ "$SIMULATE" != 1 ]; then
        local installed candidate
        installed="$(dpkg-query -W -f='${Version}' gh 2>/dev/null || true)"
        candidate="$(LC_ALL=C apt-cache policy gh | awk '/Candidate:/ {print $2; exit}')"
        if [ -n "$candidate" ] && [ "$candidate" != "(none)" ] && [ "$installed" != "$candidate" ]; then
            log "   gh を ${installed} から ${candidate}（公式）へ入れ替えます"
            DEBIAN_FRONTEND=noninteractive apt-get install -y gh
        fi
    fi
}

app_claude_desktop() {
    local key=/usr/share/keyrings/claude-desktop-archive-keyring.asc
    install_key https://downloads.claude.ai/claude-desktop/key.asc "$key"
    # Anthropic documents this fingerprint; refuse a key that does not match.
    if ! output_matches '^fpr:::::::::31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE:' gpg --show-keys --with-colons "$key"; then
        echo "Claude アプリの署名鍵の指紋が公式の値と一致しません" >&2
        rm -f "$key"
        return 1
    fi
    write_apt_source /etc/apt/sources.list.d/claude-desktop.list \
        "deb [arch=amd64,arm64 signed-by=${key}] https://downloads.claude.ai/claude-desktop/apt/stable stable main"
    apt_install claude-desktop
}

app_cursor() {
    install_key https://downloads.cursor.com/keys/anysphere.asc /etc/apt/keyrings/cursor.gpg
    write_apt_source /etc/apt/sources.list.d/cursor.list \
        "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/cursor.gpg] https://downloads.cursor.com/aptrepo stable main"
    apt_install cursor
}

app_wezterm() {
    # The stable 20240203 build predates Wayland/NVIDIA fixes; the nightly is published daily.
    install_key https://apt.fury.io/wez/gpg.key /usr/share/keyrings/wezterm-fury.gpg
    write_apt_source /etc/apt/sources.list.d/wezterm.list \
        "deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *"
    apt_install wezterm-nightly
}

app_docker() {
    install_key https://download.docker.com/linux/ubuntu/gpg /etc/apt/keyrings/docker.asc
    write_apt_source /etc/apt/sources.list.d/docker.sources "$(printf '%s\n' \
        'Types: deb' \
        'URIs: https://download.docker.com/linux/ubuntu' \
        "Suites: ${CODENAME}" \
        'Components: stable' \
        "Architectures: ${ARCH}" \
        'Signed-By: /etc/apt/keyrings/docker.asc')"
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

app_nvidia_container_toolkit() {
    local keyring=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    install_key https://nvidia.github.io/libnvidia-container/gpgkey "$keyring"
    local list
    list="$(curl -fsSL --retry 3 https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed "s#deb https://#deb [signed-by=${keyring}] https://#g")"
    write_apt_source /etc/apt/sources.list.d/nvidia-container-toolkit.list "$list"
    apt_install nvidia-container-toolkit
    if [ "$SIMULATE" = 1 ]; then
        return 0
    fi
    nvidia-ctk runtime configure --runtime=docker
    if systemd_running; then
        systemctl restart docker
    fi
}

app_coolercontrol() {
    local keyring=/usr/share/keyrings/coolercontrol-archive-keyring.gpg
    install_key https://apt.coolercontrol.org/coolercontrol-archive-keyring.gpg "$keyring"
    write_apt_source /etc/apt/sources.list.d/coolercontrol.sources "$(printf '%s\n' \
        'Types: deb' \
        'URIs: https://apt.coolercontrol.org/ubuntu' \
        'Suites: stable' \
        'Components: main' \
        "Signed-By: ${keyring}")"
    apt_install coolercontrol
    if [ "$SIMULATE" != 1 ] && systemd_running; then
        systemctl enable --now coolercontrold
    fi
}

# ---------------------------------------------------------- vendor .deb packages
# These register their own update repository (Chrome, ChatGPT) or update themselves.

app_chrome() {
    install_deb_from_url google-chrome-stable \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
}

app_chatgpt() {
    install_deb_from_url chatgpt \
        https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb
}

app_discord() {
    install_deb_from_url discord 'https://discord.com/api/download?platform=linux&format=deb'
}

app_obsidian() {
    # Some Obsidian releases carry only the Android build, so search recent releases.
    local url
    url="$(github_asset_url obsidianmd/obsidian-releases '/obsidian_[0-9.]+_amd64\.deb$')"
    install_deb_from_url obsidian "$url"
}

app_opencode() {
    local url
    url="$(github_asset_url anomalyco/opencode '/opencode-desktop-linux-amd64\.deb$')"
    install_deb_from_url opencode "$url"
}

app_lm_studio() {
    # LM Studio does not need Bionic (a separate agent app from the same company).
    # The "latest" link redirects to the current versioned .deb (package name lm-studio).
    install_deb_from_url lm-studio 'https://lmstudio.ai/download/latest/linux/x64?format=deb'
}

app_handy() {
    local url
    url="$(github_asset_url cjpais/Handy '/Handy_[0-9.]+_amd64\.deb$')"
    install_deb_from_url handy "$url"
}

app_lact() {
    local url
    url="$(github_asset_url ilya-zlobintsev/LACT '/lact-[0-9.]+-[0-9]+\.amd64\.ubuntu-2604\.deb$')"
    install_deb_from_url lact "$url"
    if [ "$SIMULATE" != 1 ] && systemd_running; then
        systemctl enable --now lactd
    fi
}

# ------------------------------------------------------------- Ubuntu archive

app_desktop_utilities() {
    local pkgs
    mapfile -t pkgs < <(read_package_list apt-desktop-apps.txt)
    apt_install "${pkgs[@]}"
}

app_thunderbird() {
    if [ "$IN_CONTAINER" = 1 ]; then
        log "   Thunderbird は snap 経由のため、コンテナでは省略"
        return 0
    fi
    # On 26.04 this transitional package installs the auto-updating snap.
    apt_install thunderbird
}

ALL_APPS=(gh chrome claude_desktop chatgpt cursor wezterm discord obsidian opencode lm_studio handy
    desktop_utilities coolercontrol lact thunderbird docker nvidia_container_toolkit)

selected=("$@")
if [ "${#selected[@]}" -eq 0 ]; then
    selected=("${ALL_APPS[@]}")
fi

apt_refresh force
for app in "${selected[@]}"; do
    app=${app//-/_}
    if ! declare -F "app_${app}" >/dev/null; then
        log "不明な項目: ${app}（候補: ${ALL_APPS[*]}）"
        FAILED_ITEMS+=("unknown-${app}")
        continue
    fi
    run_item "$app" "app_${app}"
done

finish_script
