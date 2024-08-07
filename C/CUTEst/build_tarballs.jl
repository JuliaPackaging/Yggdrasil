# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CUTEst"
version = v"2.2.1"

# Collection of sources required to build ThinASLBuilder
sources = [
    GitSource("https://github.com/ralna/CUTEst.git", "e692555a86bc6ef81977d3e7893566ee28f5b115"),
]

# Bash recipe for building across all platforms
script = raw"""
# Update Ninja
cp ${host_prefix}/bin/ninja /usr/bin/ninja

cd ${WORKSPACE}/srcdir/CUTEst

meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                     --prefix=$prefix \
                     -Dquadruple=true

meson compile -C builddir
meson install -C builddir

meson setup builddir_shared --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                            --prefix=$prefix \
                            -Dquadruple=true \
                            -Ddefault_library=shared

meson compile -C builddir_shared
meson install -C builddir_shared

install_license lgpl-3.0.txt
"""

# These are the platforms we will build for by default, unless further platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("lib/libcutest_single.a", :libcutest_single_a),
    FileProduct("lib/libcutest_double.a", :libcutest_double_a),
    FileProduct("lib/libcutest_quadruple.a", :libcutest_quadruple_a),
    LibraryProduct("libcutest_single", :libcutest_single),
    LibraryProduct("libcutest_double", :libcutest_double),
    LibraryProduct("libcutest_quadruple", :libcutest_quadruple),
]

dependencies = [
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
