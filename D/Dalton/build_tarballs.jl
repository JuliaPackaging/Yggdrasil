# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
name = "Dalton"
version = v"2020.1"

# Collection of sources required to build imagemagick
sources = [
    GitSource("https://gitlab.com/dalton/dalton/", "9d7c5e435b75a9695d5ac8714121d12e6486149f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
git submodule update --init --recursive
# remove bad flags
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/rm_bad_flags.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/no_lseek64_freebsd.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/use_target_processor.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/fix_OPENDX_freebsd.patch"

# these platforms are seeing excessive compilation on the last compile step
if [[ ${bb_full_target} == armv6l-linux-musleabihf-libgfortran3* ]] ||
   [[ ${bb_full_target} == armv7l-linux-musleabihf-libgfortran3* ]] ||
   [[ ${bb_full_target} == armv7l-linux-gnueabihf-libgfortran5*  ]] ; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/no_unroll_loop.patch"
fi

./setup --blas="${libdir}/libopenblas.${dlext}" --lapack="${libdir}/liblapack.${dlext}" \
    --prefix="${prefix}" -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cd build
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())
filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libgfortran_version(p) == v"3"), platforms)
filter!(p -> !Sys.iswindows(p), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("dalton", :dalton, "dalton"),
    ExecutableProduct("dalton.x", :dalton_x, "dalton"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LAPACK_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6",
)
