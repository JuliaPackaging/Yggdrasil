#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1

# Download and extract the lib folders from our CompilerSupportLibraries_jll.jl releases
CSL_VERSION="0.3.3+0"
for arch in i686 x86_64; do
    mkdir -p glibc-${arch} musl-${arch}
    curl -L "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v${CSL_VERSION}/CompilerSupportLibraries.v${CSL_VERSION%%+*}.${arch}-linux-gnu-libgfortran5.tar.gz" | tar --wildcards --strip-components=2 -zxv -C glibc-${arch} "./lib*/"
    curl -L "https://github.com/JuliaBinaryWrappers/CompilerSupportLibraries_jll.jl/releases/download/CompilerSupportLibraries-v${CSL_VERSION}/CompilerSupportLibraries.v${CSL_VERSION%%+*}.${arch}-linux-musl-libgfortran5.tar.gz" | tar --wildcards --strip-components=2 -zxv -C musl-${arch} "./lib*/"
done

