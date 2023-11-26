# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ghostbasil"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/biona001/ghostbasil.git", "5a7121542d39ac4439b366d0223cd117f4211681")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir ghostbasil/julia/build
cd ghostbasil/julia/build
cmake     -DJulia_PREFIX=$prefix     -DCMAKE_INSTALL_PREFIX=$prefix     -DCMAKE_FIND_ROOT_PATH=$prefix     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}     -DEigen3_DIR=$prefix/share/eigen3/cmake     -DCMAKE_BUILD_TYPE=Release     ../
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libghostbasil_wrap", :libghostbasil)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"))
    Dependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
    Dependency(PackageSpec(name="libjulia_jll", uuid="5ad3ddd2-0711-543a-b040-befd59781bbf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")
