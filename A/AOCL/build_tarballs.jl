# Copyright 2026 Advanced Micro Devices, Inc.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

using BinaryBuilder, Pkg

name = "AOCL"
version = v"5.3.1"

# Pinned to the AOCL-5.3.1-Submodules tag and its recorded submodule commits
sources = [
    GitSource("https://github.com/amd/aocl.git",
              "5018beb662bca63d29ace70da51ce322e76d9909"),
    GitSource("https://github.com/amd/aocl-utils.git",
              "deb418767224511d146fc5e6841a55a6f69e5e79"; unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/blis.git",
              "9212e3b464ef3310b093d4405222ec79afd147b4"; unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/libflame.git",
              "954fc2601f65b06e64eb5b55164d8881063a1ee1"; unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-sparse.git",
              "2e62fd859dfc40dcc1df2fc96e5994f9fd49eef4"; unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-libm-ose.git",
              "86223910103068db48f42d9cc59c0bf3fc46fa5f"; unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-compression.git",
              "ab24e65b346f48d3433f74e0fffbdc888e36736b"; unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-libmem.git",
              "be498406b4192d3a2053bbd036813ff30605c2dd"; unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/openrng.git",
              "27ade0ed417e87fddfbe7ce76f22dcda6f583cce"; unpack_target = "aocl-src"),
]

script = raw"""
export PATH="${host_bindir}:${PATH}"

AOCL_BIY=${WORKSPACE}/srcdir/aocl
SRC=${WORKSPACE}/srcdir/aocl-src

if [[ -d ${SRC}/aocl-libm-ose && ! -d ${SRC}/aocl-libm ]]; then
    mv ${SRC}/aocl-libm-ose ${SRC}/aocl-libm
fi

# AOCL-LibM's CMake calls `ldd --version` to read the glibc version (purely for
# a build-info string), but the musl-based build host has no working ldd.
# Provide a shim that reports the target sysroot's actual glibc version.
mkdir -p ${WORKSPACE}/srcdir/shim-bin
GLIBC_VERSION=$(grep -aoE 'GNU C Library.* version [0-9]+\.[0-9]+' \
    "$(cc -print-file-name=libc.so.6)" | grep -oE '[0-9]+\.[0-9]+' | head -1)
cat > ${WORKSPACE}/srcdir/shim-bin/ldd <<EOF
#!/bin/bash
echo "ldd (GNU libc) ${GLIBC_VERSION}"
EOF
chmod +x ${WORKSPACE}/srcdir/shim-bin/ldd
export PATH="${WORKSPACE}/srcdir/shim-bin:${PATH}"

cd ${AOCL_BIY}

# Build one AOCL variant. Args: <cmake-preset> [extra cmake args...]
# The unified library name is controlled by AOCL_SINGLE_LIBRARY_NAME, which sets
# both the file name (libaocl.so) and the SONAME. The ILP64 variant overrides it
# to "aocl64" so libaocl64.so gets a distinct SONAME; a plain rename would leave
# the SONAME as libaocl.so and make the dynamic linker dedup the two variants
# when both are loaded in the same process.
build_aocl_variant() {
    local preset="$1"; shift
    rm -rf ${AOCL_BIY}/build
    cmake --preset ${preset} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_Fortran_COMPILER=$(which gfortran) \
        -DOpenMP_libomp_LIBRARY= \
        -DBUILD_CORES=${nproc} \
        -DUSE_SOURCES_FROM_SUBMODULES=OFF \
        -DENABLE_AOCL_DA=OFF \
        -DENABLE_AOCL_CRYPTO=OFF \
        -DUTILS_PATH=${SRC} \
        -DBLAS_PATH=${SRC} \
        -DLAPACK_PATH=${SRC} \
        -DSPARSE_PATH=${SRC} \
        -DLIBM_PATH=${SRC} \
        -DCOMPRESSION_PATH=${SRC} \
        -DLIBMEM_PATH=${SRC} \
        -DOPENRNG_PATH=${SRC}/openrng \
        "$@"
    cmake --build ${AOCL_BIY}/build --config Release --target install -j${nproc}
}

# LP64 variant -> libaocl.so
build_aocl_variant aocl-linux-make-lp-ga-gcc-config

# ILP64 variant -> libaocl64.so (distinct SONAME via AOCL_SINGLE_LIBRARY_NAME)
build_aocl_variant aocl-linux-make-ilp-ga-gcc-config \
    -DAOCL_SINGLE_LIBRARY_NAME=aocl64

# AOCL always emits static archives alongside the shared libraries. Drop them.
rm -f ${prefix}/lib/libaocl*.a

install_license ${AOCL_BIY}/LICENSE.txt
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
]

products = [
    LibraryProduct("libaocl", :libaocl),
    LibraryProduct("libaocl64", :libaocl64),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"14.2.0",
    lock_microarchitecture = false,
    julia_compat = "1.9",
)
 
