#!/bin/bash

for f in *; do
    if [[ ! -d ${f} ]]; then
        continue
    fi

    rm -rf ${f}/products
done
