include("../coin-or-common.jl")

name = "SHOT"
version = v"1.0.1"

sources = [
    GitSource(
        "https://github.com/coin-or/SHOT.git",
        "d2c99ba451689bd4a80b5e170855b94f0d300b05",
    ),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/SHOT
git submodule update --init --recursive
atomic_patch -p1 ../patches/0001-Fix-whole-archive-linker-options-for-macOS.patch

if [[ "${target}" == *-darwin* ]]; then
    # Work around the issue
    #     /workspace/srcdir/SHOT/src/Model/../Model/Simplifications.h:1370:26: error: 'value' is unavailable: introduced in macOS 10.14
    #                     optional.value()->coefficient *= -1.0;
    #                              ^
    #     /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/c++/v1/optional:947:27: note: 'value' has been explicitly marked unavailable here
    #         constexpr value_type& value() &
    #                               ^
    export CXXFLAGS="-mmacosx-version-min=10.15"
    # ...and install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
elif [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
fi

mkdir -p build
cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHAS_CBC=on \
    -DCBC_DIR=${prefix} \
    -DHAS_IPOPT=on \
    -DIPOPT_DIR=${prefix} \
    -DHAS_AMPL=on \
    -DGENERATE_EXE=on \
    ..

make -j${nproc}
make install
"""

products = [
    ExecutableProduct("SHOT", :amplexe),
]

dependencies = [
    Dependency("ASL_jll", ASL_version),
    Dependency("Cbc_jll", Cbc_version),
    Dependency("Ipopt_jll", Ipopt_version),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"9",
)
