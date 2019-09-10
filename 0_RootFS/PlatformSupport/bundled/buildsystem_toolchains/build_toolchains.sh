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

function meson_cpu_from_target()
{
    if [[ "$1" == x86_64* ]]; then
        echo "x86_64"
    elif [[ "$1" == i686* ]]; then
        echo "i686"
    elif [[ "$1" == arm* ]]; then
        echo "armv7l"
    elif [[ "$1" == aarch64* ]]; then
        echo "aarch64"
    elif [[ "$1" == powerpc64le* ]]; then
        echo "ppc64le"
    else
        echo "ERROR: Unknown CPU!" >&2
        exit 1
    fi
}

function meson_cpu_family_from_target()
{
    if [[ "$1" == x86_64* ]]; then
        echo "x86_64"
    elif [[ "$1" == i686* ]]; then
        echo "x86"
    elif [[ "$1" == arm* ]]; then
        echo "arm"
    elif [[ "$1" == aarch64* ]]; then
        echo "aarch64"
    elif [[ "$1" == powerpc64le* ]]; then
        echo "ppc64"
    else
        echo "ERROR: Unknown CPU family!" >&2
        exit 1
    fi
}


# All the targets that get the simple_gcc AND simple_clang templates
function simple_targets()
{
    # First the glibc and musl targets for the ones we love
    for arch in aarch64 i686 x86_64; do
        echo -n "${arch}-linux-gnu "
        echo -n "${arch}-linux-musl "
    done
    # I wave my ARMs back and forth
    echo -n "arm-linux-gnueabihf "
    echo -n "arm-linux-musleabihf "
    # FreeBSD is free again!
    echo -n "x86_64-unknown-freebsd11.1 "
    # Power Overwhelming
    echo -n "powerpc64le-linux-gnu "
    # Clean your Windows (TM)
    for arch in i686 x86_64; do
        echo -n "${arch}-w64-mingw32 "
    done
}

function all_targets()
{
    simple_targets
    echo -n "x86_64-apple-darwin14 "
}

ENABLED_TARGETS="${1:-$(all_targets)}"

for TARGET in ${ENABLED_TARGETS}; do
    echo "Generating ${TARGET}..."
    mkdir -p ${TARGET}
        
    ARCH=$(arch_from_target "${TARGET}")
    OS=$(os_from_target "${TARGET}")
    MESON_CPU=$(meson_cpu_from_target "${TARGET}")
    MESON_CPU_FAMILY=$(meson_cpu_family_from_target "${TARGET}")

    # MacOS has a special toolchain template
    CMAKE_SRC="cmake_simple"
    if [[ ${TARGET} == x86_64-apple-darwin14 ]]; then
        CMAKE_SRC="cmake_macos"
    fi

    # First, CMake toolchains...
    template "${CMAKE_SRC}_gcc.j2" "{{TARGET}}=${TARGET}" "{{ARCH}}=${ARCH}" "{{OS}}=${OS}" > ${TARGET}/${TARGET}_gcc.cmake
    template "${CMAKE_SRC}_clang.j2" "{{TARGET}}=${TARGET}" "{{ARCH}}=${ARCH}" "{{OS}}=${OS}" > ${TARGET}/${TARGET}_clang.cmake

    # On FreeBSD and MacOS we actually want to default to clang, otherwise gcc
    if [[ ${TARGET} == *freebsd* ]] || [[ ${TARGET} == *-darwin-* ]]; then
        ln -fs ${TARGET}_clang.cmake ${TARGET}/${TARGET}.cmake
    else
        ln -fs ${TARGET}_gcc.cmake ${TARGET}/${TARGET}.cmake
    fi

    # Next, generate meson templates
    template meson.j2 "{{TARGET}}=${TARGET}" "{{ARCH}}=${ARCH}" "{{OS}}=$(echo ${OS} | tr '[:upper:]' '[:lower:]')" \
                      "{{CPU}}=${MESON_CPU}" "{{CPU_FAMILY}}=${MESON_CPU_FAMILY}"> ${TARGET}/${TARGET}.meson
done
