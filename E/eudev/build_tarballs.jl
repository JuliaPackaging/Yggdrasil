# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "eudev"
version = v"3.2.14"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eudev-project/eudev", "9e7c4e744b9e7813af9acee64b5e8549ea1fbaa3"),
    DirectorySource(joinpath(@__DIR__, "patches"))
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eudev*
apk add libxslt-dev docbook-xsl
./autogen.sh

# Only apply the patch for musl targets
if [[ "${target}" == *"musl"* ]]; then
    atomic_patch -p0 ../musl.patch
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libudev", :libudev),
    ExecutableProduct("udevd", :udevd, "sbin"),
    ExecutableProduct("udevadm", :udevadm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="gperf_jll", uuid="1a1c6b14-54f6-533d-8383-74cd7377aa70"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
