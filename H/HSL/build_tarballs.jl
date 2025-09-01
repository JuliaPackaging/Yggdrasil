# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HSL"
version = v"4.0.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/libHSL.git", "d725da5edae4a5f1a1267d295e28ad99803d4d89")
]

# Bash recipe for building across all platforms
script = raw"""
# Update Ninja
cp ${host_prefix}/bin/ninja /usr/bin/ninja

QUADRUPLE="true"
if [[ "${target}" == *arm* ]] || [[ "${target}" == *aarch64-linux* ]] || [[ "${target}" == *riscv64* ]] || [[ "${target}" == *aarch64-unknown-freebsd* ]] || [[ "${target}" == *powerpc64le-linux-gnu* ]]; then
    QUADRUPLE="false"
fi

cd $WORKSPACE/srcdir/libHSL/libhsl
meson setup builddir_libhsl --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release
meson compile -C builddir_libhsl
meson install -C builddir_libhsl

cd $WORKSPACE/srcdir/libHSL/hsl_subset
meson setup builddir_hsl_subset -Dquadruple=${QUADRUPLE} --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release
meson compile -C builddir_hsl_subset
meson install -C builddir_hsl_subset
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libhsl", :libhsl),
    LibraryProduct("libhsl_subset", :libhsl_subset),
    LibraryProduct("libhsl_subset_64", :libhsl_subset_64)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; clang_use_lld=false, julia_compat="1.6")
