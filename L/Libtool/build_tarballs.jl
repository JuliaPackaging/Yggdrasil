# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libtool"
version = v"2.4.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/libtool/libtool-$(version).tar.gz",
                  "04e96c2404ea70c590c546eba4202a4e12722c640016c12b9b2f1ce3d481e9a8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libtool-*
for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${patch}
done
# Prevent `help2man` needing to be run because we patched `libtoolize`
touch doc/libtoolize.1

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} SHELL=/bin/bash
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    FileProduct("bin/libtool", :libtool),
    FileProduct("bin/libtoolize", :libtoolize),
    LibraryProduct("libltdl", :libltdl),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# build count: 2
