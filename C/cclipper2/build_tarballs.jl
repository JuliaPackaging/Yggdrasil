# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cclipper2"
version = v"0.1.0"

# The wrapper is hosted in Clipper.jl
sources = [
    GitSource("https://github.com/JuliaGeometry/Clipper.jl.git", "70dbd8c78ada6af5cc27f8aae8c3562e2bcc0475"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Clipper.jl/deps/cwrapper
install -Dvm 644 cclipper2.h "${includedir}/cclipper2.h"

${CXX} -std=c++17 -O2 -fPIC -shared -DUSINGZ -DCLIPPER2_HI_PRECISION \
    -fvisibility=hidden -fvisibility-inlines-hidden \
    -I${includedir} \
    -o "${libdir}/libcclipper2.${dlext}" \
    cclipper2.cpp \
    -L${libdir} -L${prefix}/lib -lClipper2Z

install_license ${prefix}/share/licenses/Clipper2/LICENSE
"""

# Must match Clipper2_jll's platforms, since libcclipper2 links its C++ library.
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcclipper2", :libcclipper2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Clipper2_jll"; compat="=2.0.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10")
