# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "stb_image"
version = v"2.32.0"

# stb_jll currently provides stb_image.h from v2.27, so use the upstream
# header directly to build the v2.32.0 library. Upstream has no tags or releases;
# the version is based on the v2.32 version reported in the header.
# Collection of sources required to complete build
sources = [
    FileSource("https://raw.githubusercontent.com/nothings/stb/9f755b604db3492df2cbeb39bf84b81e3e3932e3/stb_image.h", "deb4f18c9ca21b751a1323019031c94c0bf5ca1d2929ef5913cc56f00aab6e91"),
    FileSource("https://raw.githubusercontent.com/nothings/stb/9f755b604db3492df2cbeb39bf84b81e3e3932e3/LICENSE", "eb36e45c704dd0b59730115523e089b051852625b4db0a6fe76c991900af20e7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
printf '#define STB_IMAGE_IMPLEMENTATION\n#include "stb_image.h"' > stb_image.c
mkdir -vp ${libdir}
${CC} -shared -o ${libdir}/stb_image.${dlext} -fPIC stb_image.c
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("stb_image", :stb_image)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
