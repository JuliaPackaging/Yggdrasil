# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "p3a"
version = v"1.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sandialabs/p3a.git", "271cd1d77fbc850aa4ddfb015b59176926670b3b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/p3a/
mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=OFF \
-DBUILD_SHARED_LIBS=ON \
-DKokkos_COMPILE_LANGUAGE=CXX

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental = true))
#Kokkos is only available on 64 bit
filter!(p -> nbits(p) != 32, platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libp3a", :libp3a)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Kokkos_jll", uuid="c1216c3d-6bb3-5a2b-bbbf-529b35eba709"))
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#needed a c++17 compiler, 7 and 8 kept refusing to acknowledge std::byte and a few other template things for some reason?!
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
