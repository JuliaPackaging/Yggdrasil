#!/bin/bash

# This script autogenerates our cmake toolchain files from
# the .j2 template files sitting in this directory.

function template()
{
    data="$(cat "$1")"
    shift
    
    # Loop over all other arguments, subbing old=new mappings
    while [[ "$#" -gt 0 ]]; do
        SUB=${1%%=*}
        data=$(sed "s&$SUB&${1:${#SUB}+1}&g" <<< "$data")
        shift
    done

    echo "$data"
}

function arch_from_target()
{
    if [[ "$1" == powerpc64le-* ]]; then
        echo "ppc64le"
    else
        echo "$1" | cut -d'-' -f1
    fi
}

function os_from_target()
{
    if [[ "$1" == *linux* ]]; then
        echo "Linux"
    elif [[ "$1" == *mingw* ]]; then
        echo "Windows"
    elif [[ "$1" == *darwin* ]]; then
        echo "Darwin"
    elif [[ "$1" == *freebsd* ]]; then
        echo "FreeBSD"
    else
        echo "ERROR: Unknown OS!" >&2
        exit 1
    fi
}

# All the targets that get the simple_gcc AND simple_clang templates
function simple_targets()
{
    # First the glibc and musl targets
    for arch in aarch64 i686 x86_64; do
        echo "${arch}-linux-gnu"
        echo "${arch}-linux-musl"
    done
    # I wave my arms back and forth
    echo "arm-linux-gnueabihf"
    echo "arm-linux-musleabihf"
    # FreeBSD is free again!
    echo "x86_64-unknown-freebsd11.1"
    # Power Overwhelming
    echo "powerpc64le-linux-gnu"
    # Clean your windows
    for arch in i686 x86_64; do
        echo "${arch}-w64-mingw32"
    done
}

for TARGET in $(simple_targets); do
    mkdir -p ${TARGET}
    ARCH=$(arch_from_target "${TARGET}")
    OS=$(os_from_target "${TARGET}")
    template simple_gcc.j2 "{{TARGET}}=${TARGET}" "{{ARCH}}=${ARCH}" "{{OS}}=${OS}" > ${TARGET}/${TARGET}_gcc.toolchain
    template simple_clang.j2 "{{TARGET}}=${TARGET}" "{{ARCH}}=${ARCH}" "{{OS}}=${OS}" > ${TARGET}/${TARGET}_clang.toolchain

    # On all of these platforms, we default to gcc
    ln -fs ${TARGET}_gcc.toolchain ${TARGET}/${TARGET}.toolchain
done

# On FreeBSD we actually want to default to clang. :P
TARGET=x86_64-unknown-freebsd11.1
ln -fs ${TARGET}_clang.toolchain ${TARGET}/${TARGET}.toolchain

# macOS has its own templates because it is a special snoflake
TARGET=x86_64-apple-darwin14
mkdir -p ${TARGET}
template macos_gcc.j2 "{{TARGET}}=${TARGET}" "{{ARCH}}=x86_64" "{{OS}}=Darwin" > ${TARGET}/${TARGET}_gcc.toolchain
template macos_clang.j2 "{{TARGET}}=${TARGET}" "{{ARCH}}=x86_64" "{{OS}}=Darwin" > ${TARGET}/${TARGET}_clang.toolchain
ln -fs ${TARGET}_clang.toolchain ${TARGET}/${TARGET}.toolchain
