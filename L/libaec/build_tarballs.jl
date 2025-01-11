# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libaec"
version = v"1.1.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.dkrz.de/k202009/libaec.git",
              "58677dbbf080bac17bbb8717d32e63feb4e20115")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libaec*

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build
install -Dvm 755 "build/src/graec${exeext}" -t "${bindir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsz", :libsz),
    LibraryProduct("libaec", :libaec),
    ExecutableProduct("graec", :aec)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 1
