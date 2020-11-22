# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibBirch"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lawmurray/Birch.git", "a533990b59b04ef4cd20f8d4fe91c4a220df1cfa"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Birch/libbirch/
autoreconf -vi
CPPFLAGS="-I${prefix}/include" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-debug --enable-release
make -j${nproc}
make install

# install LICENSE
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Native support for Windows is not yet provided:
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libbirch", :libbirch),
    LibraryProduct("libbirch-debug", :libbirch_debug),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("Eigen_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"5")
