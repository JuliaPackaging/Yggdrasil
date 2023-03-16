# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GANAK"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/meelgroup/ganak.git", "1aa12a37aa2e65043948a986abe55911aaa5d2fb")
]

# Bash recipe for building across all platforms
script = raw"""
cd ganak/

mkdir build; cd build

if [[ ${target} != x86_64-linux* ]]; then
  # clhash only works on x86_64 linux platforms
  disablepcc=-DDOPCC=OFF
fi

cmake $disablepcc \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_SKIP_BUILD_RPATH=TRUE \
      ..
make -j${nproc}
install -v ganak -Dt $bindir 
install -v src/libganak* -Dt $libdir
cp -d src/libganak.${dlext} $libdir
install -v src/clhash/libclhash* -Dt $libdir
install -v src/component_types/libcomponent_types* -Dt $libdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p->(Sys.islinux(p) || Sys.isapple(p)), supported_platforms())
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("ganak", :ganak)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"); compat="6.2.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
