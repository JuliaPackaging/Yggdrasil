using BinaryBuilder, Pkg

name = "Chuffed"

version = v"0.14.0"

sources = [
    GitSource(
        "https://github.com/chuffed/chuffed.git",
        "f698d5623bb0c2bcd497388ba966f0436d62caf4",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/chuffed

sed -i 's/#include <Windows\.h>/#include <windows.h>/' chuffed/support/misc.h chuffed/globals/blackbox.h

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCP_PROFILER=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    ExecutableProduct("fzn-chuffed", :fznchuffed),
]

dependencies = [
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
    preferred_gcc_version = v"12",
    julia_compat = "1.6",
)
