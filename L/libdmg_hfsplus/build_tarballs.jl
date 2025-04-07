# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdmg_hfsplus"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mozilla/libdmg-hfsplus.git", "d6287b5afc2406b398de42f74eba432f2123b937")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p /tmp/libdmg-build
cd /tmp/libdmg-build
cmake /workspace/srcdir/libdmg-hfsplus   -DZLIB_INCLUDE_DIR=$WORKSPACE/destdir/include   -DZLIB_LIBRARY=$WORKSPACE/destdir/lib/libz.so   -DBZIP2_INCLUDE_DIR=$WORKSPACE/destdir/include   -DBZIP2_LIBRARIES=$WORKSPACE/destdir/lib/libbz2.so   -DLIBLZMA_INCLUDE_DIR=$WORKSPACE/destdir/include   -DLIBLZMA_LIBRARY=$WORKSPACE/destdir/lib/liblzma.so   -DOPENSSL_INCLUDE_DIR=$WORKSPACE/destdir/include   -DOPENSSL_CRYPTO_LIBRARY=$WORKSPACE/destdir/lib/libcrypto.so   -DWITH_LZFSE=OFF
make
install -Dvm 755 "/tmp/libdmg-build/dmg/dmg${exeext}" "${bindir}/dmg${exeext}"
cd /workspace/srcdir/libdmg-hfsplus/
install_license LICENSE 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("dmg", :dmg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"))
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
