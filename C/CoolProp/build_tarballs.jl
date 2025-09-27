# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CoolProp"
version = v"7.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/projects/coolprop/files/CoolProp/$version/source/CoolProp_sources.zip", "cfcdaf02042e693ed5329ea444704ab1765a24502beb83adb657a92da53b66d5"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.0.sdk.tar.xz",
                  "d3feee3ef9c6016b526e1901013f264467bb927865a03422a9cb925991cc9783"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

sed -i 's/Windows/windows/' source/dev/Tickets/60.cpp
sed -i 's/Windows/windows/' source/src/CPfilepaths.cpp
# Do not add `-m32`/`-m64` flags
sed -i 's/-m${BITNESS}//' source/CMakeLists.txt

if [[ "${target}" == *apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX11.0.sdk
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    export MACOSX_DEPLOYMENT_TARGET=10.14
fi

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCOOLPROP_SHARED_LIBRARY=ON ../source/
VERBOSE=ON cmake --build . --config Release --target CoolProp -- -j${nproc}
install -Dvm 0755 "libCoolProp.${dlext}" "${libdir}/libCoolProp.${dlext}"
install_license $WORKSPACE/srcdir/source/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> arch(p) != "powerpc64le", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libCoolProp", :libcoolprop)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
