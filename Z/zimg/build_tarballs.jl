# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "zimg"
version = v"3.0.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sekrit-twc/zimg", "e5b0de6bebbcbc66732ed5afaafef6b2c7dfef87"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zimg
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libzimg", :libzimg)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6", clang_use_lld=false)
