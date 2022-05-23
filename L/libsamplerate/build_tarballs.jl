# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsamplerate"
version = v"0.1.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.mega-nerd.com/SRC/libsamplerate-0.1.9.tar.gz", "0a7eb168e2f21353fb6d84da152e4512126f7dc48ccb0be80578c565413444c1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libsamplerate-0.1.9
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsamplerate", :libsamplerate),
    ExecutableProduct("sndfile-resample", :sndfile_resample)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
