# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "z3"
version = v"4.8.8"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Z3Prover/z3.git",
              "ad55a1f1c617a7f0c3dd735c0780fc758424c7f1"),
]

# Bash recipe for building across all platforms
script = raw"""
case $target in
  x86_64-linux-gnu)
    Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target/julia-1.3.1
    ;;
  x86_64-apple-darwin14|x86_64-w64-mingw32)
    Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target/juliabin
    ;;
esac

cd $WORKSPACE/srcdir/z3/

mkdir z3-build && cd z3-build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH="${prefix}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DZ3_BUILD_JULIA_BINDINGS=True \
    -DJulia_PREFIX=${Julia_PREFIX} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    Windows(:x86_64),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libz3", :libz3),
    LibraryProduct("libz3jl", :libz3jl),
    ExecutableProduct("z3", :z3)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("libcxxwrap_julia_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
