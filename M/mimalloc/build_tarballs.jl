# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mimalloc"
version = v"2.1.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/mimalloc.git",
              "1b3cb0258fc475460ed19cdb78feaebd69cef0c6"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-linux-musl* ]]; then
    # Musl doesn't support init-exec TLS
    CMAKE_FLAGS=(-DMI_LOCAL_DYNAMIC_TLS=ON) 
fi
cd $WORKSPACE/srcdir/mimalloc
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DMI_BUILD_OBJECT=OFF \
    -DMI_INSTALL_TOPLEVEL=ON \
    -DMI_BUILD_TESTS=OFF \
    -DMI_OVERRIDE=OFF \
    "${CMAKE_FLAGS}"
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmimalloc", :libmimalloc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6.1.0")
