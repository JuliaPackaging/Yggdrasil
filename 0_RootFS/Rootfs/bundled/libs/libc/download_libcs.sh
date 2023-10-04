#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1

# Download and extract the lib folders from our Glibc releases
for arch in i686 x86_64; do
    rm -rf glibc-${arch}
    mkdir -p glibc-${arch}
    curl -L "https://github.com/JuliaBinaryWrappers/Glibc_jll.jl/releases/download/Glibc-v2.34.0%2B0/Glibc.v2.34.0.${arch}-linux-gnu.tar.gz" | tar --wildcards --strip-components=1 -zxv -C glibc-${arch} "lib*/"
done

# Next, do the same for musl
for arch in i686 x86_64; do
    rm -rf musl-${arch}
    mkdir -p musl-${arch}
    curl -L "https://github.com/JuliaBinaryWrappers/Musl_jll.jl/releases/download/Musl-v1.2.4%2B0/Musl.v1.2.4.${arch}-linux-musl.tar.gz" | tar --wildcards --strip-components=1 -zxv -C musl-${arch} "lib*/"
done
