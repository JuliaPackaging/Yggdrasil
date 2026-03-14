# Build script for Musica_jll
# To test locally:
#   julia build_tarballs.jl --verbose --debug
#
# To build for a specific platform:
#   julia build_tarballs.jl x86_64-linux-gnu-cxx11

using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Musica"
version = v"0.14.4"

# Collection of sources required to build Musica
sources = [
    GitSource("https://github.com/NCAR/musica.git",
              "5ce469e046fd365e238bc21118b96bafb7773261"),
]

# Bash recipe for building across all platforms
script = raw"""

# not enough space in /tmp
export TMPDIR=$WORKSPACE/tmp
mkdir -p $TMPDIR

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
    -DMUSICA_BUILD_SHARED_LIBS=ON 

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE

# On Windows, CMake installs DLLs for LIBRARY targets to lib/ instead of bin/
# BinaryBuilder requires all DLLs to be in bin/
if [[ "${target}" == *-mingw* ]]; then
    mv -f "${prefix}/lib/"*.dll "${prefix}/bin/" 2>/dev/null || true
fi
"""

sources, script = require_macos_sdk("14.5", sources, script, deployment_target="15.0")

# grab all of the platforms supported by libjulia
include(joinpath(YGGDRASIL_DIR, "L", "libjulia", "common.jl"))
platforms = expand_cxxstring_abis(supported_platforms())

# FreeBSD 13.4's libc++ in BinaryBuilder's sysroot is too old to support
# std::formatter<ErrorLocation> used by mechanism_configuration
filter!(!Sys.isfreebsd, platforms)

# libcxxwrap_julia_jll does not provide artifacts for armv6l, armv7l, or i686-linux-musl
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "armv7l", platforms)
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)

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
    Dependency("libcxxwrap_julia_jll"; compat="~0.14.9"),
    HostBuildDependency(PackageSpec(name="CMake_jll", version=v"3.31.9+0")),
]

# Build the tarballs
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10",
    preferred_gcc_version=v"13",
    dont_dlopen=true
)
