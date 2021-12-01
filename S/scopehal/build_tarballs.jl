# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

julia_version = v"1.6.0"

name = "scopehal"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/azonenberg/scopehal.git", "db29f07e396667135ccf02b37e27f68b8d4998a1"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scopehal/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-replace-color-with-string.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-avx2-fma-on-llvm.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-rigol-function-generator.patch
git submodule update --init
cd xptools
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-musl.patch
cd ../..
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DJulia_PREFIX=${prefix} \
    .
make -j${nproc}
make install
install_license scopehal/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
# ARM targets are not supported
platforms = filter!(p -> BinaryBuilder.proc_family(p) == "intel", platforms)
# LLVM does not yet support OpenMP on BinaryBuilder
 filter!(p -> !Sys.isapple(p), platforms)
platforms = expand_cxxstring_abis(platforms; skip=p->false)


# The products that we will ensure are always built
products = Product[
    LibraryProduct("libscopehal", :scopehal)
    LibraryProduct("libscopehalwrapper", :scopehalwrapper)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="yaml_cpp_jll", uuid="01fea8cc-7d33-533a-824e-56a766f4ffe8"))
    Dependency(PackageSpec(name="ffts_jll", uuid="84ad2fbc-dacc-5b40-99f5-8db9d02a0a8a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency("libcxxwrap_julia_jll")
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
