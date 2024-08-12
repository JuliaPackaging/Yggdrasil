# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kokkos"
version_string = "4.3.1"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kokkos/kokkos.git", "6ecdf605e0f7639adec599d25cf0e206d7b8f9f5"),
    # Kokkos requires macOS 10.13 or later
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.13.sdk.tar.xz",
                  "a3a077385205039a7c6f9e2c98ecdf2a720b2a819da715e03e0630c75782c1e4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/kokkos

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.13
    pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -a usr/* "/opt/${target}/${target}/sys-root/usr/"
    cp -a System "/opt/${target}/${target}/sys-root/"
    popd
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_CXX_STANDARD=17 \
    -DKokkos_ENABLE_OPENMP=ON \
    -DKokkos_ENABLE_SERIAL=ON

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
#Kokkos assumes a 64-bit build, remove 32-bit platforms
filter!(p -> nbits(p) != 32, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libkokkoscore", :libkokkoscore),
    LibraryProduct("libkokkoscontainers", :libkokkoscontainers),
    LibraryProduct("libkokkossimd", :libkokkossimd)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
