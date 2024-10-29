using BinaryBuilder

name = "libplist"
version = v"2.3.0"

# Collection of sources required to build libplist
sources = [
    GitSource("https://github.com/libimobiledevice/libplist.git",
              "72480212cd8ec0ab8d0b5064df52c146cac603b4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libplist*/

# This project uses bash-isms in its configuration
export CONFIG_SHELL=/bin/bash
autoreconf -f -i

# Build without python bindings
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
            --without-cython --enable-shared

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("plistutil", :plistutil),
    LibraryProduct(["libplist", "libplist-2", "libplist-2.0"], :libplist),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
