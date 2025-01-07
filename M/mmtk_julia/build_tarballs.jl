# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mmtk_julia"
version = v"0.30.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mmtk/mmtk-julia.git", "b69acf5af7a7dd97c1cc6fd99f7c2d51b477f214")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mmtk-julia/
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
    LibraryProduct("libmmtk_julia", :libmmtk_julia)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c], preferred_gcc_version = v"10", dont_dlopen=true)
