# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ghostbasil"
version = v"0.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/biona001/ghostbasil.git", "5a7121542d39ac4439b366d0223cd117f4211681")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p ghostbasil/julia/build
cd ghostbasil/julia/build

cmake \
    -DJulia_PREFIX=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DEigen3_DIR=$prefix/share/eigen3/cmake \
    -DCMAKE_BUILD_TYPE=Release \
    ../

make
make install

# install license
install_license $WORKSPACE/srcdir/ghostbasil/R/LICENSE.md
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
    LibraryProduct("libghostbasil_wrap", :libghostbasil_wrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency("Eigen_jll"),
    BuildDependency("libjulia_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
