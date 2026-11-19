# Copyright Advanced Micro Devices, Inc.
# SPDX-License-Identifier: MIT

using BinaryBuilder, Pkg

name = "AOCL"
version = v"6.0.0"

sources = [
    GitSource("https://github.com/amd/aocl.git",             "9f36290abb78846f2697d97c5d3001b52092cdf2"; tag = "6.0.0"),
    GitSource("https://github.com/amd/aocl-utils.git",       "059f9a41719c6586507ad6f0bd9095565a1bbbf1"; tag = "6.0.0", unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/blis.git",             "e5f75c24bdb8670ff648da7e483eb7e51b28a1db"; tag = "6.0.0", unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/libflame.git",         "698c6f8070c5dbf551eb2dc801908db4ac0f5916"; tag = "6.0.0", unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-sparse.git",      "47238ec3c4848e8509def31dac3aaec93e84abd5"; tag = "6.0.0", unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-libm-ose.git",    "155b5ab00879dd0d4fcf89aa602415ced5546218"; tag = "6.0.0", unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-compression.git", "bf3bc76d8cbd63609ca65ebb1427daa28337cd4e"; tag = "6.0.0", unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/openrng.git",          "5c05f2eeb6effc696b0df6ce8be1fcbe855b631b"; tag = "6.0.0", unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-fftz.git",        "88da98aa1f08409df7d6dea62509cc6a550cce6a"; tag = "6.0.0", unpack_target = "aocl-src"),
    GitSource("https://github.com/amd/aocl-dlp.git",         "57f3dfcd532e3ccd8a51eeaa018625c8fd36d8c5"; tag = "6.0.0", unpack_target = "aocl-src"),
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
        -DENABLE_AOCL_DA=OFF \
        -DENABLE_AOCL_CRYPTO=OFF \
        -DENABLE_AOCL_LIBMEM=OFF \
        -DUTILS_PATH=${SRC} \
        -DBLAS_PATH=${SRC} \
        -DLAPACK_PATH=${SRC} \
        -DSPARSE_PATH=${SRC} \
        -DLIBM_PATH=${SRC} \
        -DCOMPRESSION_PATH=${SRC} \
        -DOPENRNG_PATH=${SRC} \
        -DFFTZ_PATH=${SRC} \
        -DDLP_PATH=${SRC} \
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
    HostBuildDependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"14.2.0",
    lock_microarchitecture = false,
    julia_compat = "1.10",
)
 
