# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Rclone"
version = v"1.65.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/rclone/rclone/releases/download/v$(version)/rclone-v$(version).tar.gz",
                  "904b906cc465dd679a00487497e3891d33fca6b6e25c184400bccfb248344f39"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd rclone*

# Cross-compiling fails at the moment; see <https://github.com/rclone/rclone/issues/7560>
atomic_patch -p0 ../patches/nfs.patch

make

# install manually as `make install` doesn't include $exeext
install -d ${bindir}
install -t ${bindir} ${GOPATH}/bin/rclone${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("rclone", :rclone)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c], julia_compat="1.6")
