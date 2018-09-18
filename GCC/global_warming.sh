#!/bin/bash

MACHINES=$(julia -e 'using BinaryBuilder; println(join(triplet.(supported_platforms()), " "))')
VERSIONS="4.8.5" # 7.1.0 8.1.0"

for m in $MACHINES; do
    for v in $VERSIONS; do
        if [[ -f $(echo products/GCC*${v}*${m}*.tar.gz) ]]; then
            echo "Skipping $m $v"
            continue
        fi
        julia --color=yes build_tarballs.jl --verbose --debug --gcc-version $v $m
    done
done
