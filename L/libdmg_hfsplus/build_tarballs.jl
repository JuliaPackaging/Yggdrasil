# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdmg_hfsplus"
version = v"0.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mozilla/libdmg-hfsplus.git", "d6287b5afc2406b398de42f74eba432f2123b937")
]

# Bash recipe for building across all platforms
script = raw"""
    cd $WORKSPACE/srcdir/libdmg-hfsplus

    cmake -B build \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DZLIB_INCLUDE_DIR=${includedir} \
        -DZLIB_LIBRARY="${libdir}/libz.${dlext}" \
        -DBZIP2_INCLUDE_DIR=${includedir}  \
        -DBZIP2_LIBRARIES="${libdir}/libbz2.${dlext}" \
        -DLIBLZMA_INCLUDE_DIR=${includedir} \
        -DLIBLZMA_LIBRARY="${libdir}/liblzma.${dlext}" \
        -DOPENSSL_INCLUDE_DIR=${includedir} \
        -DOPENSSL_CRYPTO_LIBRARY="${libdir}/libcrypto.${dlext}" \
        -DLZFSE_INCLUDE_DIR=${includedir} \
        -DLZFSE_LIBRARY="${libdir}/liblzfse.${dlext}"
 
    cmake --build build --parallel ${nproc}

    install -Dvm 755 "build/dmg/dmg${exeext}" "${bindir}/dmg${exeext}"
    install -Dvm 755 "build/hdutil/hdutil${exeext}" "${bindir}/hdutil${exeext}"
    install -Dvm 755 "build/hfs/hfsplus${exeext}" "${bindir}/hfsplus${exeext}"
    install_license LICENSE 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("dmg", :dmg)
    ExecutableProduct("hdutil", :hdutil)
    ExecutableProduct("hfsplus", :hfsplus)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LZFSE_jll")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.9"),
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800")),
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.16")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
