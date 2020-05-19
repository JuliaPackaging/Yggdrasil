#!/bin/bash

# First, source .env to get the environment
source .env

# Next, extract the heinous `sandbox` invocation, with some even more heinous `sed` commands:
SANDBOX_CMD=$(sed -n -E '/ExecStart\s+=/,/bin\/bash/p' agent_startup.conf | sed -E 's/ExecStart\s+=//' | sed -E 's_/bin/bash -c .*_/bin/bash_')

# If an agent index has been given, use it, otherwise default to agent 1
if [[ ! -z "$1" ]]; then
    export AGENT_IDX=$(echo "$1" | sed -e 's/agent_//')
else
    export AGENT_IDX=1
fi

# Run the `sandbox` command:
eval "${SANDBOX_CMD}"
