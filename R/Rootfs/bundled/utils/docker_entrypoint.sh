#!/bin/bash
set -e

# This script used to recreate the logic within `sandbox` for coalescing mounts.
# This is used by the docker runner only.
function join_by { local IFS="$1"; shift; echo "$*"; }

for f in /opt/*; do
    # Okay this is actually kind of annoying once it's working
    #echo "[docker-entrypoint] Coalescing ${f}"
    mount -t overlay overlay -olowerdir=$(join_by ":" "${f}"/*) "${f}"
done

exec "$@"
