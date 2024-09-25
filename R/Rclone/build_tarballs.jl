# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Rclone"
version = v"1.68.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/rclone/rclone/releases/download/v$(version)/rclone-v$(version).tar.gz",
                  "c5d45b83dd008d08a0903eebf1578a11a40a77152226e22ce5e9287b9db05579"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd rclone*

# Don't run any locally built executables when building for Windows (this doesn't work when cross-compiling).
# We are losing "version information and icon resources" in our `rclone` executable.
atomic_patch -p0 ../patches/make.patch

make

# install manually as `make install` doesn't include $exeext
install -d ${bindir}
install -t ${bindir} ${GOPATH}/bin/rclone${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("rclone", :rclone)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c], julia_compat="1.6")
