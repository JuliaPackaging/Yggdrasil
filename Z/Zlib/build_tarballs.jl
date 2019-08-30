using BinaryBuilder

# zlib version
name = "Zlib"
version = v"1.2.11"

# Collection of sources required to build zlib
sources = [
    "https://zlib.net/zlib-$(version).tar.gz" =>
    "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zlib-*

# On windows platforms, our ./configure and make invocations differ a bit
if [[ ${target} == *-w64-mingw* ]]; then
    EXTRA_CONFIGURE_FLAGS="--sharedlibdir=${prefix}/bin"
    EXTRA_MAKE_FLAGS="SHAREDLIB=libz.dll SHAREDLIBM=libz-1.dll SHAREDLIBV=libz-1.2.11.dll LDSHAREDLIBC= "
fi

if [[ ${target} == *-freebsd* ]]; then
    cmake -DCMAKE_INSTALL_PREFIX=${prefix}
else
    ./configure ${EXTRA_CONFIGURE_FLAGS} --prefix=${prefix}
fi

make install ${EXTRA_MAKE_FLAGS} -j${nproc}
"""

# Build for ALL THE PLATFORMS!
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libz", :libz),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
