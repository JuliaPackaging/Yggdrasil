# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Jinja2Cpp"
version = v"1.3.2"

# Collection of sources required to build CMake
sources = [
    GitSource("https://github.com/jinja2cpp/Jinja2Cpp.git", "86dfb939b5c2beb7fabddae2df386be4e7fb9507"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
    "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Jinja2Cpp

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `shared_timed_mutex` and `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

apk del cmake

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p2 ${f}
done

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DJINJA2CPP_BUILD_SHARED=ON \
    -DJINJA2CPP_STRICT_WARNINGS=OFF

cmake --build build --parallel ${nproc}
cmake --install build

install_license ${WORKSPACE}/srcdir/Jinja2Cpp/LICENSE
"""

# Build for all supported platforms.
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libjinja2cpp", :libjinja2cpp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="1.79"),
    HostBuildDependency(PackageSpec(; name="CMake_jll"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
