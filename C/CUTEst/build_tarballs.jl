# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CUTEst"
version = v"2.2.0"

# Collection of sources required to build ThinASLBuilder
sources = [
    GitSource("https://github.com/ralna/CUTEst.git", "05822b4a5d57fa65270b8d6e63c066da6da373d1"),
]

# Bash recipe for building across all platforms
script = raw"""
# Update Ninja
cp ${host_prefix}/bin/ninja /usr/bin/ninja

cd ${WORKSPACE}/srcdir/CUTEst

meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                     --prefix=$prefix

meson compile -C builddir
meson install -C builddir

install_license lgpl-3.0.txt
"""

# These are the platforms we will build for by default, unless further platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("lib/libcutest_single.a", :libcutest_single),
    FileProduct("lib/libcutest_double.a", :libcutest_double),
]

dependencies = [
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
