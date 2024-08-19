using BinaryBuilder, Pkg

name = "Chuffed"

version = v"0.13.2"

sources = [
    GitSource(
        "https://github.com/chuffed/chuffed.git",
        "2016f7eb7943a86b9ce93bb70b821d701667a5ca",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/chuffed
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
    preferred_gcc_version = v"5",
    julia_compat = "1.6",
)
