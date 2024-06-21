# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Uno"

version = "v1.0.0"

sources = [
    GitSource(
        "https://github.com/cvanaret/Uno.git",
        "888114ce7d5e1d208ed8865dc836e4b94017e6a8",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/Uno
mkdir -p build
cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..

make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("Uno", :amplexe),
]

dependencies = [
    Dependency("ASL_jll", compat="0.1.3"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
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
    julia_compat = "1.9",
)
