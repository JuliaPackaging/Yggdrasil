#!/bin/bash

NUM_AGENTS=8
for AGENT_IDX in $(seq 1 ${NUM_AGENTS}); do
    systemctl --user stop azp_agent_${AGENT_IDX}
done
