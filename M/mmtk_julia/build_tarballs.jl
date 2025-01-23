# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mmtk_julia"
version = v"0.30.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mmtk/mmtk-julia.git", "c9e046baf3a0d52fe75d6c8b28f6afd69b045d95")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mmtk-julia/
# do a non-moving build until we support moving Immix
MMTK_MOVING=0 make release 

# Install
install -Dvm 755 "mmtk/target/${rust_target}/release/libmmtk_julia.${dlext}" -t "${libdir}"
install -Dvm 644 "mmtk/api/mmtk.h" "${includedir}/mmtk.h"
install -Dvm 644 "mmtk/api/mmtkMutator.h" "${includedir}/mmtkMutator.h"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libmmtk_julia", :libmmtk_julia; dont_dlopen=true)
    FileProduct("include/mmtk.h", :mmtk_h)
    FileProduct("include/mmtkMutator.h", :mmtkMutator_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"10", dont_dlopen=true)
