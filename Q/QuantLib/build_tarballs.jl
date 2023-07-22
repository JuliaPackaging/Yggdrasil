# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QuantLib"
version = v"1.31"

sources = [
    GitSource("https://github.com/lballabio/QuantLib.git", "38551644cb8b9b6b794f443225e522296ce08331"),
]

# Bash recipe for building across all platforms
script = raw"""
# needed for now
# from https://github.com/JuliaPackaging/Yggdrasil/blob/6ee3af28801d635e4419c0e9ca8db4325568714d/S/SCIP/build_tarballs.jl#L16C1-L24C3
# clock_gettime requires linking to librt -lrt with old glibc
# remove when CMake accounts for this
if [[ "${target}" == *86*-linux-gnu ]]; then
   export LDFLAGS="-lrt"
elif [[ "${target}" == *-mingw* ]]; then
   # this is required to link to bliss on mingw
   export LDFLAGS=-L${libdir}
fi

cd ${WORKSPACE}/srcdir/QuantLib
install_license LICENSE.TXT
mkdir build
cd build
cmake -G "Unix Makefiles" \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
# Note that QuantLib also builds quantlib-benchmark and quantlib-test-suite which could be included as ExecutableProducts
products = [
    LibraryProduct("libQuantLib", :libQuantLib),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8.1.0", julia_compat="1.6")
