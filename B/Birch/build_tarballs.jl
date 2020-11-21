# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Birch"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lawmurray/Birch.git", "a533990b59b04ef4cd20f8d4fe91c4a220df1cfa"),
]

# Bash recipe for building across all platforms
script = raw"""
# install the driver
cd ${WORKSPACE}/srcdir/Birch/driver/
autoreconf -vi
CPPFLAGS="-I${prefix}/include" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

# install license
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# GLOB_NOMAGIC is not supported by musl
filter!(p -> libc(p) != "musl", platforms)

# Native support for Windows is not yet provided
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("birch", :birch),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("boost_jll"),
    Dependency("LibYAML_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"5")
