# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name    = "r3d"
version = v"0.1.0"  # JLL package version; upstream r3d is untagged.

# Collection of sources required to complete build
# Pinned to upstream HEAD as of 2026-04-25.
sources = [
    GitSource("https://github.com/devonmpowell/r3d.git",
              "58dfbfb2fd2a89e36e3c7ceb5ca6aef3f9c4c4e6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# r3d ships a template config header but expects the user to provide
# r3d-config.h on the include path. Create one that bumps the maximum
# vertex count for clipped polyhedra (R3D) while leaving R2D at its
# upstream default of 256.
mkdir -p libr3d
cat > libr3d/r3d-config.h <<'EOF'
#ifndef R3D_CONFIG_H
#define R3D_CONFIG_H
#define R3D_MAX_VERTS 512
#endif
EOF

# Build a single shared library from the four C sources. ${dlext} expands
# to the correct platform-specific extension (so / dylib / dll), and
# ${CC} is the cross-compiler set up by BinaryBuilder for ${target}.
mkdir -p ${libdir}
${CC} -O3 -fPIC -shared \
    -I libr3d -I r3d/src \
    r3d/src/r3d.c r3d/src/v3d.c r3d/src/r2d.c r3d/src/v2d.c \
    -lm \
    -o ${libdir}/libr3d.${dlext}

install_license r3d/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libr3d", :libr3d),
]

# Dependencies that must be installed before this package can be built
# r3d only needs libm, which is provided by every libc and so does not
# need to be listed explicitly.
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6")
