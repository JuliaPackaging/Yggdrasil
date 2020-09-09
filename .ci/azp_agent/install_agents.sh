#!/bin/bash

set -e

NUM_AGENTS=8
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
mkdir -p ${HOME}/.config/systemd/user
source .env

# Create a nice little rootfs for our agents
if [[ ! -d "${STORAGE_DIR}/rootfs" ]]; then
    echo "Setting up rootfs..."
    mkdir -p "${STORAGE_DIR}/rootfs"
    sudo debootstrap --variant=minbase --include=ssh,curl,libicu63,git,xz-utils,bzip2,unzip,p7zip,zstd,expect,locales,libgomp1 buster "${STORAGE_DIR}/rootfs"

    # Remove special `dev` files
    sudo rm -rf "${STORAGE_DIR}/rootfs/dev/*"
    # take ownership
    sudo chown $(id -u):$(id -g) -R "${STORAGE_DIR}/rootfs"
    # Remove `_apt` user so that `apt` doesn't try to `setgroups()`
    sed '/_apt:/d' -i "${STORAGE_DIR}/rootfs/etc/passwd"

    # Set up the one true locale
    echo "en_US.UTF-8 UTF-8" >> ${STORAGE_DIR}/rootfs/etc/locale.gen
    sudo chroot ${STORAGE_DIR}/rootfs locale-gen
fi

if [[ ! -f "${STORAGE_DIR}/rootfs/etc/gitconfig" ]]; then
    # Add `git` username
    echo "[user]"                               > ${STORAGE_DIR}/rootfs/etc/gitconfig
    echo "    email = juliabuildbot@gmail.com" >> ${STORAGE_DIR}/rootfs/etc/gitconfig
    echo "    name = jlbuild"                  >> ${STORAGE_DIR}/rootfs/etc/gitconfig
fi

# Add SSH keys
SSH_DIR="${STORAGE_DIR}/rootfs/root/.ssh"
if [[ ! -d "${SSH_DIR}" ]]; then
    mkdir -p "${SSH_DIR}"
    cp -a ./yggdrasil_rsa "${SSH_DIR}/id_rsa"
    chmod 0600 "${SSH_DIR}/id_rsa"
    chmod 0700 "${SSH_DIR}"
fi

if [[ ! -f "${STORAGE_DIR}/rootfs/usr/local/bin/julia" ]]; then
    # Install Julia into the rootfs
    echo "Installing Julia..."
    # RIGHT INTO THE DANGEEERRR ZOOOOOONE
    JULIA_URL="https://julialangnightlies-s3.julialang.org/bin/linux/x64/julia-latest-linux64.tar.gz"
    #JULIA_URL="https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.1-linux-x86_64.tar.gz"
    curl -# -L "$JULIA_URL" | tar --strip-components=1 -zx -C "${STORAGE_DIR}/rootfs/usr/local"
fi

if [[ ! -f "${STORAGE_DIR}/rootfs/sandbox" ]]; then
    # Install `sandbox` and `run_agent.sh` into the rootfs
    echo "Installing sandbox..."
    SANDBOX_URL="https://github.com/JuliaPackaging/Yggdrasil/raw/master/0_RootFS/Rootfs/bundled/utils/sandbox"
    curl -# -L "${SANDBOX_URL}" -o "${STORAGE_DIR}/rootfs/sandbox"
    chmod +x "${STORAGE_DIR}/rootfs/sandbox"
    cp -a "${SRC_DIR}/run_agent.sh" "${STORAGE_DIR}/rootfs/run_agent.sh"
fi

if [[ ! -d "${STORAGE_DIR}/rootfs/agent" ]]; then
    # Install agent executable
    AZP_AGENTPACKAGE_URL=$(
        curl -LsS -u "user:${AZP_TOKEN}" \
            -H 'Accept:application/json;api-version=3.0-preview' \
            "${AZP_URL}/_apis/distributedtask/packages/agent?platform=linux-x64" |
        jq -r '.value | map([.version.major,.version.minor,.version.patch,.downloadUrl]) | sort | .[length-1] | .[3]'
    )

    if [ -z "$AZP_AGENTPACKAGE_URL" -o "$AZP_AGENTPACKAGE_URL" == "null" ]; then
        echo 1>&2 "error: could not determine a matching Azure Pipelines agent - check that account '$AZP_URL' is correct and the token is valid for that account"
        exit 1
    fi

    echo "Installing AZP agent..."
    mkdir -p "${STORAGE_DIR}/rootfs/agent"
    curl -LsS "$AZP_AGENTPACKAGE_URL" | tar -xz -C "${STORAGE_DIR}/rootfs/agent"
fi

# Install mknod startup unit
envsubst "\$SRC_DIR" <"loopback_startup.conf" >"${HOME}/.config/systemd/user/loopback_startup.unit"

for AGENT_IDX in $(seq 1 $NUM_AGENTS); do
    export SRC_DIR STORAGE_DIR AGENT_IDX
    envsubst "\$SRC_DIR \$STORAGE_DIR \$AGENT_IDX"  <"agent_startup.conf" >"${HOME}/.config/systemd/user/azp_agent_${AGENT_IDX}.service"
done

# Reload systemd user daemon
systemctl --user daemon-reload

for AGENT_IDX in $(seq 1 ${NUM_AGENTS}); do
    systemctl --user stop azp_agent_${AGENT_IDX} || true
    # Enable and start AZP agents
    systemctl --user enable azp_agent_${AGENT_IDX}
    systemctl --user start azp_agent_${AGENT_IDX}
done
