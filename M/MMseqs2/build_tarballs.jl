# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MMseqs2"
version = v"13"

# MMseqs2 seem to use as versioning scheme of "major version + first 5
# characters of the tagged commit"
# https://github.com/soedinglab/MMseqs2/releases
version_commitprefix = "45111"


# Possible build variants
# - OpenMP (default)
# - MPI (-DHAVE_MPI=1)
# - single-threaded (-DREQUIRE_OPENMP=0)

# TODO
# - built-in zstd, replace with Zstd_jll? (-DUSE_SYSTEM_ZSTD=1 cmake option)
# - aarch64 macos: single-threaded, openmp not used
# - os-specific build script examples under util/build_{osx,windows}

# Build failures
# - windows:
#   - cmake can't find openmp, this check can be avoided by passing -DREQUIRE_OPENMP=0 to cmake
#   - compile error afterwards
#     error: ‘posix_memalign’ was not declared in this scope
#     (and more following errors)
# - macos aarch64
#   - g++-11 build fails (tries to compile for x86 simd)
#   - compiles with clang, but openmp doesn't work
# - i686: compile error due to bitwidth issues, haven't investigated more
# - powerpc build fails with g++-7.x (tries to compile for x86 simd),
#   works with g++-8.x and above


# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/soedinglab/MMseqs2/archive/refs/tags/$(version.major)-$(version_commitprefix).tar.gz",
                  "6444bb682ebf5ced54b2eda7a301fa3e933c2a28b7661f96ef5bdab1d53695a2"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd MMseqs2-*/

# patch CMakeLists.txt so it doesn't set -march unnecessarily on ARM
atomic_patch -p1 ../patches/arm-simd-march-cmakefile.patch

# macos x86_64: use gcc/g++ so we can use openmp
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    CMAKE_TARGET_TOOLCHAIN="${CMAKE_TARGET_TOOLCHAIN/%.cmake/_gcc.cmake}"
    echo "[INFO] setting CMAKE_TARGET_TOOLCHAIN = ${CMAKE_TARGET_TOOLCHAIN}"
fi

# macos aarch64: disable openmp as it doesn't work with clang
EXTRA_CMAKE_FLAGS=
if [[ "${target}" == aarch64-apple-darwin* ]]; then
    EXTRA_CMAKE_FLAGS="-DREQUIRE_OPENMP=0"
fi

# architecture extensions
ARCH_FLAGS=
if [[ "${target}" == x86_64-* || "${target}" == i686-* ]]; then
    ARCH_FLAGS="-DHAVE_SSE2=1 -DHAVE_SSE4_1=1 -DHAVE_AVX2=1"
elif [[ "${target}" == powerpc64le-* ]]; then
    ARCH_FLAGS="-DHAVE_POWER8=1 -DHAVE_POWER9=1"
elif [[ "${target}" == aarch64-* ]]; then
    ARCH_FLAGS="-DHAVE_ARM8=1"
fi

mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=RELEASE \
    -DNATIVE_ARCH=0 ${EXTRA_CMAKE_FLAGS} ${ARCH_FLAGS}
make -j${nproc}
make install

install_license ../LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true, exclude = p -> Sys.iswindows(p) || arch(p) == "i686")
# expand cxxstring abis on platforms where we use g++
platforms = expand_cxxstring_abis(platforms; skip = p -> Sys.isfreebsd(p) || (Sys.isapple(p) && arch(p) == "aarch64"))

# The products that we will ensure are always built
products = [
    ExecutableProduct("mmseqs", :mmseqs)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="Bzip2_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"8")
