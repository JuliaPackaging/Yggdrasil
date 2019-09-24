#!/bin/bash
set -e

# This script used to recreate the logic within `sandbox` for coalescing mounts.
# This is used by the docker runner only.
function join_by { local IFS="$1"; shift; echo "$*"; }

# Create workspace for... for our workspace...
mount -t tmpfs -osize=1G tmpfs /overlay_workdir

for f in /opt/*; do
    bname=$(basename "${f}")

    # Only coalesce triplet-style names:
    if [[ "${bname}" != *-*-* ]]; then
        continue
    fi

    mkdir -p /overlay_workdir/upper/${bname}
    mkdir -p /overlay_workdir/work/${bname}
    mount -t overlay overlay -olowerdir=$(join_by ":" "${f}"/*) -oupperdir=/overlay_workdir/upper/${bname} -oworkdir=/overlay_workdir/work/${bname} "${f}"
done

exec "$@"
