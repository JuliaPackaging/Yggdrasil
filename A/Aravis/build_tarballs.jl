# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Aravis"
version = v"0.8.26"

sources = [
    GitSource("https://github.com/AravisProject/aravis.git",
              "e977fa4eedc8c4f4747ff370d53621b369930fe9"),
    
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aravis

# needed for glib-compile-resources
apk add glib-dev

mkdir build-aravis

cd build-aravis
meson .. \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dtests=false
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libaravis","libaravis-0","libaravis-0.8"], :libaravis),
    ExecutableProduct(["arv-tool","arv-tool-0","arv-tool-0.8"], :arv_tool),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll"; compat="2.68.3"),
    Dependency("libusb_jll")
    ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
