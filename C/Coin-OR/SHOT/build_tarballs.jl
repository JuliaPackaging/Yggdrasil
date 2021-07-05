include("../coin-or-common.jl")

name = "SHOT"
version = v"1.0.1"

sources = [
    GitSource(
        "https://github.com/coin-or/SHOT.git",
        "d2c99ba451689bd4a80b5e170855b94f0d300b05",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/SHOT
git submodule update --init --recursive
mkdir -p build
cd build

if [[ "${target}" == *-darwin* ]]; then
    # Work around the issue
    #     /workspace/srcdir/SHOT/src/Model/../Model/Simplifications.h:1370:26: error: 'value' is unavailable: introduced in macOS 10.14
    #                     optional.value()->coefficient *= -1.0;
    #                              ^
    #     /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/c++/v1/optional:947:27: note: 'value' has been explicitly marked unavailable here
    #         constexpr value_type& value() &
    #                               ^
    export CXXFLAGS="-mmacosx-version-min=10.14"
fi

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
