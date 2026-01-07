# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CUTEst"
version = v"2.5.6"

# Collection of sources required to build CUTEst
sources = [
    GitSource("https://github.com/ralna/CUTEst.git", "c0b28c8fd041228071838c1aed03d4ebbf5e64f6"),
]

# Bash recipe for building across all platforms
script = raw"""
# Update Ninja
cp ${host_prefix}/bin/ninja /usr/bin/ninja

QUADRUPLE="true"
if [[ "${target}" == *arm* ]] || [[ "${target}" == *i686* ]] || [[ "${target}" == *aarch64-linux* ]] || [[ "${target}" == *aarch64-unknown-freebsd* ]] || [[ "${target}" == *powerpc64le-linux-gnu* ]] || [[ "${target}" == *riscv64* ]]; then
    QUADRUPLE="false"
fi

mkdir ${includedir}
cd ${WORKSPACE}/srcdir/CUTEst

meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                     --prefix=$prefix \
                     -Dquadruple=${QUADRUPLE}

meson compile -C builddir
meson install -C builddir

meson setup builddir_shared --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                            --prefix=$prefix \
                            -Dquadruple=${QUADRUPLE} \
                            -Ddefault_library=shared

meson compile -C builddir_shared
meson install -C builddir_shared

install_license lgpl-3.0.txt
"""

# These are the platforms we will build for by default, unless further platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> libgfortran_version(p) != v"3", platforms)
platforms = filter(p -> libgfortran_version(p) != v"4", platforms)
platforms = filter(p -> nbits(p) != 32, platforms)

# The products that we will ensure are always built
products = [
    FileProduct("lib/libcutest_single.a", :libcutest_single_a),
    FileProduct("lib/libcutest_double.a", :libcutest_double_a),
    # FileProduct("lib/libcutest_quadruple.a", :libcutest_quadruple_a), <-- not available on all platforms
    LibraryProduct("libcutest_single", :libcutest_single),
    LibraryProduct("libcutest_double", :libcutest_double),
    # LibraryProduct("libcutest_quadruple", :libcutest_quadruple), <-- not available on all platforms
]

dependencies = [
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
