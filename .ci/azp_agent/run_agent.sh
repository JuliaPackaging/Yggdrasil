#!/bin/bash

for idx in $(seq 1 63); do \
	if [ -e /dev/loop${idx} ]; then continue; fi; \
	sudo mknod /dev/loop${idx} b 7 ${idx}; \
	sudo chown --reference=/dev/loop0 /dev/loop${idx}; \
	sudo chmod --reference=/dev/loop0 /dev/loop${idx}; \
done

set -e

if [ -z "$AZP_URL" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "$AZP_AGENT_NAME" ]; then
  echo 1>&2 "error: missing AZP_AGENT_NAME environment variable"
  exit 1
fi

if [ -z "$AZP_PREFIX" ]; then
  echo 1>&2 "error: missing AZP_PREFIX environment variable"
  exit 1
fi

if [ -z "$AZP_TOKEN_FILE" ]; then
  if [ -z "$AZP_TOKEN" ]; then
    echo 1>&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  AZP_TOKEN_FILE="${AZP_PREFIX}/.token"
  echo -n "${AZP_TOKEN}" > "$AZP_TOKEN_FILE"
fi
# Hide the token from worker processes
unset AZP_TOKEN

rm -rf "${AZP_PREFIX}/agent"
mkdir "${AZP_PREFIX}/agent"
cd "${AZP_PREFIX}/agent"

# Download/install a version of Julia for our agent
JULIA_URL="https://julialang-s3.julialang.org/bin/linux/x64/1.3/julia-1.3.0-linux-x86_64.tar.gz"
mkdir -p "${AZP_PREFIX}/julia"
curl -# -L "$JULIA_URL" | tar --strip-components=1 -zxv -C "${AZP_PREFIX}/julia"
export PATH="${AZP_PREFIX}/julia/bin:$PATH"

cleanup() {
  if [ -e config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    ./config.sh remove --unattended \
      --auth PAT \
      --token $(cat "$AZP_TOKEN_FILE")
  fi
}

print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

# Let the agent ignore the token env variables
export VSO_AGENT_IGNORE=AZP_TOKEN,AZP_TOKEN_FILE

print_header "1. Determining matching Azure Pipelines agent..."

AZP_AGENT_RESPONSE=$(curl -LsS \
  -u user:$(cat "$AZP_TOKEN_FILE") \
  -H 'Accept:application/json;api-version=3.0-preview' \
  "$AZP_URL/_apis/distributedtask/packages/agent?platform=linux-x64")

if echo "$AZP_AGENT_RESPONSE" | jq . >/dev/null 2>&1; then
  AZP_AGENTPACKAGE_URL=$(echo "$AZP_AGENT_RESPONSE" \
    | jq -r '.value | map([.version.major,.version.minor,.version.patch,.downloadUrl]) | sort | .[length-1] | .[3]')
fi

if [ -z "$AZP_AGENTPACKAGE_URL" -o "$AZP_AGENTPACKAGE_URL" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent - check that account '$AZP_URL' is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and installing Azure Pipelines agent..."

curl -LsS $AZP_AGENTPACKAGE_URL | tar -xz & wait $!

source ./env.sh

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

print_header "3. Configuring Azure Pipelines agent..."

./config.sh --unattended \
  --agent "$AZP_AGENT_NAME" \
  --url "$AZP_URL" \
  --auth PAT \
  --token $(cat "$AZP_TOKEN_FILE") \
  --pool "${AZP_POOL:-Default}" \
  --work _work \
  --replace \
  --acceptTeeEula & wait $!

print_header "4. Running Azure Pipelines agent..."

# `exec` the node runtime so it's aware of TERM and INT signals
# AgentService.js understands how to handle agent self-update and restart
exec ./externals/node/bin/node ./bin/AgentService.js interactive
