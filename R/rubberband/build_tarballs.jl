# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rubberband"
version = v"1.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/breakfastquay/rubberband.git", "6659d61f010e19080d62aa2fd2eae88f16e5d9c9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/rubberband/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} CXXFLAGS="${CXXFLAGS} -DHAVE_FFTW3 -DHAVE_LIBSAMPLERATE" enable_vamp=no enable_ladspa=no
make DYNAMIC_LDFLAGS="${LDFLAGS} -shared -Wl" DYNAMIC_EXTENSION=".$dlext" DYNAMIC_EXTENSION=".$dlext" PROGRAM_TARGET="bin/rubberband$exeext"
make install DYNAMIC_EXTENSION=".$dlext" PROGRAM_TARGET="bin/rubberband$exeext"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("librubberband", :librubberband)
    ExecutableProduct("rubberband", :rubberband)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("FFTW_jll"),
    Dependency("libsamplerate_jll"),
    Dependency("libsndfile_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
