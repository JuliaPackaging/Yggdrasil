# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "alive2"
version = v"0.1.0"

# Collection of sources required to complete build
sources = Any[
    # An alive version from around Sep 2022 to hopefully be compatible with our LLVM version
    GitSource("https://github.com/AliveToolkit/alive2.git", "189436ffe02f44b710111ee5de06ca6b91aaff74"),
    # DirectorySource("./bundled") - Implicitly added by the LLVM configure_build
]

include("../../L/LLVM/common.jl")

_, _, llvm_sources, llvm_script, platforms, _, llvm_dependencies =
    configure_build(ARGS, v"15.0.7"; eh_rtti=true)
append!(sources, llvm_sources)

# Bash recipe for building across all platforms
script = llvm_script * raw"""
# Build alive2
apk add re2c
cd $WORKSPACE/srcdir/alive2
for f in ${WORKSPACE}/srcdir/alive_patches/*.patch; do
    atomic_patch -p1 ${f}
done
install_license LICENSE
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DBUILD_TV=1 -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
    ExecutableProduct("alive", :alive)
]

# Dependencies that must be installed before this package can be built
dependencies = Any[
    Dependency(PackageSpec(name="z3_jll", uuid="1bc4e1ec-7839-5212-8f2f-0d16b7bd09bc"))
]
append!(dependencies, llvm_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"11.1.0")
