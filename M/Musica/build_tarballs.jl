# Build script for Musica_jll
# To test locally:
#   julia --project=@BinaryBuilder build_tarballs.jl --verbose --debug
#
# To build for a specific platform:
#   julia --project=@BinaryBuilder build_tarballs.jl x86_64-linux-gnu-cxx11

using BinaryBuilder, Pkg

name = "Musica"
version = v"0.14.4"

# Collection of sources required to build Musica
sources = [
    GitSource("https://github.com/NCAR/musica.git",
              "f7252d14f53caa2b37cbf2419fdbcbbcddf4c795"),
    ArchiveSource("https://github.com/joseluisq/MacOSX-SDKs/releases/download/15.5/MacOSX15.5.sdk.tar.xz",
                  "c15cf0f3f17d714d1aa5a642da8e118db53d79429eb015771ba816aa7c6c1cbd"),
]

# Bash recipe for building across all platforms
script = raw"""

apple_sdk_root=""
if [[ "${target}" == *-apple-darwin* ]]; then
    # Install a newer SDK which supports C++20
    # including std::format and concepts... which were added even later than c++20 support
    # for some reason, anything less than 15.5 doesn't compile with mechanism configuration, I guess because of the custom formatter
    # for error location (include/mechanism_configuration/error_location.hpp)
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX15.5.sdk
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    export MACOSX_DEPLOYMENT_TARGET=15.5
fi

cd $WORKSPACE/srcdir/musica

# Needs cmake >= 3.24 provided by jll
apk del cmake

# Configure MUSICA with Julia wrapper enabled
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix}" \
    -DJulia_PREFIX=${prefix} \
    -DMUSICA_BUILD_C_CXX_INTERFACE=ON \
    -DMUSICA_ENABLE_JULIA=ON \
    -DMUSICA_ENABLE_MICM=ON \
    -DMUSICA_ENABLE_TUVX=OFF \
    -DMUSICA_ENABLE_CARMA=OFF \
    -DMUSICA_ENABLE_TESTS=OFF \
    -DMUSICA_ENABLE_INSTALL=ON \
    -DMUSICA_BUILD_SHARED_LIBS=ON \
    ${apple_sdk_root:+-DCMAKE_OSX_SYSROOT=${apple_sdk_root} -DCMAKE_OSX_DEPLOYMENT_TARGET=15.5} \

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE

# On Windows, CMake installs DLLs for LIBRARY targets to lib/ instead of bin/
# BinaryBuilder requires all DLLs to be in bin/
if [[ "${target}" == *-mingw* ]]; then
    mv -f "${prefix}/lib/"*.dll "${prefix}/bin/" 2>/dev/null || true
fi
"""

# These are the platforms the libcxxwrap_julia_jll is built on.
include("../../L/libjulia/common.jl")
julia_versions = [v"1.10", v"1.11"]  # libcxxwrap ~0.13 only supports 1.10 and 1.11
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# FreeBSD 13.4's libc++ in BinaryBuilder's sysroot is too old to support
# std::formatter<ErrorLocation> used by mechanism_configuration
filter!(!Sys.isfreebsd, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmusica_julia", :libmusica_julia),
    LibraryProduct("libmusica", :libmusica),
    LibraryProduct("libmechanism_configuration", :libmechanism_configuration),
    LibraryProduct("libyaml-cpp", :libyaml_cpp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="~0.13"),
    HostBuildDependency(PackageSpec(name="CMake_jll", version=v"3.31.9")),
]

# Build the tarballs
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10, 1.11",
    preferred_gcc_version=v"13",
    dont_dlopen=true
)
