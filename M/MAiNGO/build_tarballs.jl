# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MAiNGO"
version = v"0.8.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://git.rwth-aachen.de/avt-svt/public/maingo.git", "4b52dfc73ad5fec79dd671eefea51e32de57906b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/maingo/
git remote set-url origin https://git.rwth-aachen.de/avt-svt/public/maingo.git
mkdir build
cd build
git submodule init
git submodule update -j 1


common_cmake_options="-DCMAKE_BUILD_TYPE=Release \
                     -DMAiNGO_build_standalone=True \
                     -DMAiNGO_build_shared_c_api=True \
                     -DMAiNGO_build_parser=True \
                     -DMAiNGO_build_test=False\
                     -DMAiNGO_use_cplex=False \
                     -DMAiNGO_use_melon=False"

# GCC used because of https://github.com/JuliaPackaging/Yggdrasil/issues/7139
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.15
    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
          -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake \
          ${common_cmake_options} \
          ..
else
    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
          -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
          ${common_cmake_options} \
          ..
fi



cmake --build . --config Release --parallel ${nproc}
install -Dvm 755 "MAiNGO${exeext}" "${bindir}/MAiNGO${exeext}"
install -Dvm 755 "MAiNGOcpp${exeext}" "${bindir}/MAiNGOcpp${exeext}"
install -Dvm 755 "libmaingo-c-api.${dlext}" "${libdir}/libmaingo-c-api.${dlext}"
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line


#Auditor complains about avx1.
#Without march the Auditor detects avx2
#but with march="avx2" avx512 is detected, so we build without march

platforms = supported_platforms()
#FreeBSD is not supported
filter!(!Sys.isfreebsd, platforms)
#only x64 is supported
filter!(p -> (arch(p) == "x86_64"), platforms)
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)
#We filter out gfortan 3 (seem not to have std::variant)
filter!(p -> !(libgfortran_version(p) == v"3"), platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libmaingo-c-api", :libmaingo_c_api),
    ExecutableProduct("MAiNGOcpp", :MAiNGOcpp),
    ExecutableProduct("MAiNGO", :MAiNGO)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
