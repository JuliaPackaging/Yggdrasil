# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MathPresso"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kobalicek/mathpresso.git", "a1931d967c0903a77d567b536dd4463eccffb1c6"),
    GitSource("https://github.com/asmjit/asmjit.git", "d0d14ac774977d0060a351f66e35cb57ba0bf59c")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/mathpresso/

cmake . \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release

make -j${nproc}
#installs mathpresso.h
make install

mkdir ${libdir}
mv libmathpresso.${dlext} ${libdir}

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmathpresso", :libmathpresso)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
