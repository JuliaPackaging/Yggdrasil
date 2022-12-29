# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "libseccomp"
version = v"2.5.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/seccomp/libseccomp",
              "f33f95014b36f97b42f0c2290e96d5c31647ed10")
]

# Bash recipe for building across all platforms
script = raw"""
cd libseccomp
install_license LICENSE

autoreconf -fiv
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(Sys.islinux, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libseccomp", :libseccomp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("gperf_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
