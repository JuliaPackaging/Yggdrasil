# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mmtk_julia"
version = v"0.30.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mmtk/mmtk-julia/archive/refs/tags/v$(version).tar.gz", "d0db08487adadb24c3ac4a8a6243ce895617bfc429edb008bc69db7ee7df45b4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mmtk-julia-0.30.2/
make release 
install  -Dvm 755 "mmtk/target/${rust_target}/release/libmmtk_julia.${dlext}" -t "${libdir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("lib", :libmmtk_julia)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"10")
