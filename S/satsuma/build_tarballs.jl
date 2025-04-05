# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "satsuma"
version = v"0.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/markusa4/satsuma", "be6beeb6d2538aa133b1f6b7cad84655cda950bb"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/satsuma

for f in $WORKSPACE/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cp $WORKSPACE/srcdir/tsl/* tsl/

cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
# cmake --build build --parallel ${nproc} # this builds the wrong targets, namely dejavu
# cmake --install build # this doesn't install anything
make -B build satsuma
install satsuma $bindir
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.iswindows, supported_platforms(; experimental=true)) # windows has no boost
platforms = filter(≠(Platform("x86_64","macOS")),platforms) # ld64.lld: error: undefined symbol: std::__1::__itoa::__u32toa(unsigned int, char*)

# The products that we will ensure are always built
products = [
    ExecutableProduct("satsuma", :satsuma)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("boost_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  julia_compat="1.6", preferred_gcc_version=v"13")
