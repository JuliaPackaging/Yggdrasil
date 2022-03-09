# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NOVAS"
version = v"3.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.usno.navy.mil/USNO/astronomical-applications/software-products/novas/novas-c/novasc3.1.zip",
                  "86ab6eae9d5cfbcb75ee0d2443b83d0955f05e95510e9300b6248d56c3ab3f0f"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/novasc3.1
cp $WORKSPACE/srcdir/extras/meson.build .
mkdir build && cd build
meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
install_license ${WORKSPACE}/srcdir/extras/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)


# The products that we will ensure are always built
products = [LibraryProduct("libnovas", :libnovas)]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
