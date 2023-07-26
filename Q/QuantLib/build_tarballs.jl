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
cd ${WORKSPACE}/srcdir/QuantLib
install_license LICENSE.TXT
mkdir build
cd build
if [[ "${target}" == *86*-linux-gnu ]]; then
	export LDFLAGS="-lrt"
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DQL_EXTRA_SAFETY_CHECKS=ON \
      -DBOOST_ROOT=${includedir} \
      -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -L \
      -DCMAKE_BUILD_TYPE=Release \
      -G Ninja ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# windows excluded b/c QL doesn't build with MinGW: https://github.com/JuliaPackaging/Yggdrasil/pull/7090#issuecomment-1646444669
platforms = expand_cxxstring_abis(supported_platforms(; exclude = Sys.iswindows))


# The products that we will ensure are always built
# Note that QuantLib also builds quantlib-benchmark and quantlib-test-suite which could be included as ExecutableProducts
products = [
    LibraryProduct("libQuantLib", :libQuantLib),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="=1.76.0"), # 1.76 for Julia 1.6+ | https://github.com/JuliaPackaging/Yggdrasil/issues/3024
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8.1.0", julia_compat="1.6")
