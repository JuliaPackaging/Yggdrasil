#!/bin/bash

# Patch has the almost unbelievable failure mode that it will partially apply
# a patch.  This is really bad if you want to just ignore patch return codes,
# so what we do is we build a new atomic_patch script that will apply a
# patch if (and only if) the whole thing applies cleanly.
FILE="${!#}"
FLAGS="${@:1:$#-1}"

echo "Attempting to apply $(basename "${FILE}")..." >&2
if ! patch -f -N ${FLAGS} < "${FILE}"; then
    echo "Patch $(basename "${FILE}") could not be applied! Reverting..." >&2
    for f in $(lsdiff --strip 1 "${FILE}"); do
        if [[ -f "${f}.orig" ]]; then
            mv -v "${f}.orig" "${f}"
        fi
    done
    exit 1
fi
