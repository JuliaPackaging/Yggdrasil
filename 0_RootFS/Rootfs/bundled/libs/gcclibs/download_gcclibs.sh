#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1

# Download and extract the lib folders from our CompilerSupport releases.  We take only
# the very latest versions of everything (hence the libgfortran5 at the end) os that
# we are maximally compatible.
for arch in i686 x86_64; do
    for libc in gnu musl; do
        mkdir -p ${libc}-${arch}
        curl -L "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v0.2.0%2B0/CompilerSupportLibraries.v0.2.0.${arch}-linux-${libc}-libgfortran5.tar.gz" | tar --wildcards --strip-components=2 -zxv -C ${libc}-${arch} "./lib*/"
    done
done
