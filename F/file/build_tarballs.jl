using BinaryBuilder

name = "file"

version = v"5.45"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/file/file.git",
              "4cbd5c8f0851201d203755b76cb66ba991ffd8be")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/file/

autoreconf -i -f
(
    # Do native build to get the correct version of `file` locally
    mkdir build-native && cd build-native
    export CC=${CC_BUILD}
    export CXX=${CXX_BUILD}
    export LD=${LD_BUILD}
    ../configure --prefix=${host_prefix} --host=${MACHTYPE} --build=${MACHTYPE}
    make -j${nproc}
    make install
)

autoreconf -i -f
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE}
make -j${nproc}
make install

install_license COPYING
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("file", :file),
    LibraryProduct("libmagic", :libmagic),
]
dependencies = [
    Dependency("Bzip2_jll"),
    Dependency("XZ_jll"),
    Dependency("Zlib_jll"),
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
