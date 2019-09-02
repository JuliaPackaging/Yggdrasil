#!/bin/bash

# We build a sysctl that pretends to be a BSD system when the target
# demands it be so.  We only put stuff in here that autoconf cares
# about so that it can happily think it's building withing e.g. macOS

# Only do something if we're on a BSD
if [[ "${bb_target}" == *darwin* ]] || [[ "${bb_target}" == *freebsd* ]]; then
    # Override kern.argmax (numeric only)
    if [[ "$1" == "-n" ]] && [[ "$2" == "kern.argmax" ]]; then
        getconf ARG_MAX
        exit 0
    fi

    # Override kern.argmax
    if [[ "$1" == "kern.argmax" ]]; then
        echo "kern.argmax: $(getconf ARG_MAX)"
        exit 0
    fi
fi

# Otherwise, sub off to the "real" sysctl
/sbin/_sysctl "$@"
