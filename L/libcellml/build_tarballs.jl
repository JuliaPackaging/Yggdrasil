using BinaryBuilder, Pkg

name = "libcellml"
version = v"0.6.0"

sources = [
    GitSource(
        "https://github.com/hsorby/libcellml",
        "438f64d536db5f15791b35ffa2e5dfa849f55322"),
    ArchiveSource(
        "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
        "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# https://libcellml.org/documentation/installation/build_from_source
script = raw"""
# This requires macOS 10.15
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

cd libcellml
mkdir build && cd build
cmake -DINSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TYPE=Release \
    -DTWAE=OFF \
    -DCOVERAGE=OFF \
    -DLLVM_COVERAGE=OFF \
    -DUNIT_TESTS=OFF \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# It doesn't look like this works with 32-bit systems
platforms = expand_cxxstring_abis(supported_platforms(; exclude=p->nbits(p)==32))

products = [
    LibraryProduct("libcellml", :libcellml)
]

dependencies = [
    # XML2 apparently had a breaking change, so it's important to specify the compat bound:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/9673#issuecomment-2434514026
    Dependency("XML2_jll"; compat="2.13.4"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
