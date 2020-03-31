#!/bin/bash
set -e

check()
{
    local PROJECT=$1
    local FILE="${PROJECT}/RDEPENDENCIES"
    if [[ -f "${FILE}" ]]; then
        while IFS= read -r line
        do
            echo "$line"
            check "$line"
        done < "$FILE"
    fi
}

check $1

