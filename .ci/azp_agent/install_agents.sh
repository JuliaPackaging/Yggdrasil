#!/bin/bash

set -e

NUM_AGENTS=8
SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
mkdir -p ${HOME}/.config/systemd/user

for AGENT_IDX in $(seq 1 $NUM_AGENTS); do
    export SRC_DIR
    export AGENT_IDX
    envsubst "\$HOSTNAME \$SRC_DIR \$AGENT_IDX"  <"systemd_startup.conf" >"${HOME}/.config/systemd/user/azp_agent_${AGENT_IDX}.service"
done

# Reload systemd user daemon
systemctl --user daemon-reload

for AGENT_IDX in $(seq 1 ${NUM_AGENTS}); do
    systemctl --user stop azp_agent_${AGENT_IDX} || true
    # Enable and start AZP agents
    systemctl --user enable azp_agent_${AGENT_IDX}
    systemctl --user start azp_agent_${AGENT_IDX}
done
