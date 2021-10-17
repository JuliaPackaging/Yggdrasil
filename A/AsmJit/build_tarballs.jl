# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AsmJit"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/asmjit/asmjit.git", "d0d14ac774977d0060a351f66e35cb57ba0bf59c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/asmjit/

mkdir build
cd build/

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libasmjit", :libasmjit)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
