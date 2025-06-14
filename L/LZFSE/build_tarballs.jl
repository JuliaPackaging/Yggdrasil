# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LZFSE"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lzfse/lzfse.git", "88e2d2788b4021d0b2eb9fe2d97352ae9190f128")
]

script = raw"""
    cd $WORKSPACE/srcdir/lzfse

    if [[ "${target}" == *"freebsd"* ]]; then
        # FreeBSD requires _XOPEN_SOURCE=700 to make gettimeofday() visible in <sys/time.h>
        export CFLAGS="${CFLAGS} -D_XOPEN_SOURCE=700"
    fi

    # Build with CMake
    cmake -B build \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \

    cmake --build build --parallel ${nproc}
    cmake --install build

    install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("lzfse", :lzfse),
    LibraryProduct("liblzfse", :liblzfse),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
