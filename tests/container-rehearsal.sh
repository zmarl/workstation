#!/usr/bin/env bash
# Rehearse the kit inside an ubuntu:26.04 container (run by tests/rehearse.sh on the old PC).
# Root scripts run with WORKSTATION_SIMULATE=1: repositories are really registered and .deb
# files really downloaded, but apt only resolves the installs. User scripts install for real.
set -Euo pipefail

OUT=/out
mkdir -p "$OUT"
export DEBIAN_FRONTEND=noninteractive

echo "### harness: minimal prerequisites (what 10-base.sh would have installed)"
apt-get update -qq
apt-get install -y -qq sudo curl ca-certificates gnupg jq unzip git fontconfig xz-utils bsdextrautils >/dev/null

useradd --create-home --shell /bin/bash tester
cp -r /kit /home/tester/workstation
chown -R tester: /home/tester/workstation
KIT=/home/tester/workstation

declare -A RC

run_root() {
    local name=$1
    shift
    echo "### root: ${name} $*"
    SUDO_USER=tester WORKSTATION_SIMULATE=1 WORKSTATION_CONTAINER=1 bash "$KIT/setup/${name}.sh" "$@"
    RC[$name]=$?
}

run_user() {
    local name=$1
    shift
    echo "### user: ${name} $*"
    su - tester -c "WORKSTATION_CONTAINER=1 bash $KIT/setup/${name}.sh $*"
    RC[$name]=$?
}

run_root 10-base
run_root 20-gpu
run_root 30-apps
run_root 35-permissions input ssh
run_user 40-user-tools
run_user 50-ai-config
run_user 60-dotfiles-repos
run_user 90-verify

echo "### second pass of user scripts (must be idempotent)"
run_user 50-ai-config
RC[50-ai-config-second]=${RC[50-ai-config]}
run_user 60-dotfiles-repos
RC[60-dotfiles-repos-second]=${RC[60-dotfiles-repos]}

su - tester -c "bash $KIT/setup/status.sh" || true

echo "### exit codes"
for k in "${!RC[@]}"; do
    echo "$k=${RC[$k]}"
done | sort | tee "$OUT/exit-codes.txt"

echo "### ownership inside the home directory (everything must belong to tester)"
find /home/tester ! -user tester -printf '%u %p\n' | head -n 20 | tee "$OUT/foreign-owned.txt"

cp -r /home/tester/.local/state/workstation "$OUT/state"
chmod -R a+rX "$OUT"
