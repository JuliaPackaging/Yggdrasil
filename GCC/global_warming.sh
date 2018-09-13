#!/bin/bash

MACHINES=$(julia -e 'using BinaryBuilder; println(join(triplet.(supported_platforms()), " "))')
VERSIONS="4.8.5 4.9.4 6.1.0 7.1.0 8.1.0"

for m in $MACHINES; do
    for v in $VERSIONS; do
        if [[ -f $(echo products/GCC*${v}*${m}*.tar.gz) ]]; then
            echo "Skipping $m $v"
            continue
        fi
        julia --color=yes build_tarballs.jl --gcc-version $v $m
    done
done
