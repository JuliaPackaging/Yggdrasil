# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MMseqs2"
version = v"15"
# official version: "major version + first 5 characters of tagged commit"

# url = "https://github.com/soedinglab/MMseqs2"
# description = "Search and cluster huge protein and nucleotide sequence sets"

# Possible build variants
# - OpenMP (default)
# - MPI (-DHAVE_MPI=1)
# - single-threaded (-DREQUIRE_OPENMP=0)

# TODO
# - compile with Zstd_jll instead of built-in zstd?
#   set -DUSE_SYSTEM_ZSTD=1 cmake option
#   error during cmake: expects libzstd.a
# - os-specific build script examples under util/build_{osx,windows}

# Build failures
# - windows:
#   - cmake can't find openmp, this check can be avoided by passing -DREQUIRE_OPENMP=0 to cmake
#   - compile error afterwards
#     error: ‘posix_memalign’ was not declared in this scope
#     (and more following errors)
# - i686: compile error due to bitwidth issues, haven't investigated more
# - powerpc build fails with g++-7.x (tries to compile for x86 simd),
#   works with g++-8.x and above

sources = [
    GitSource("https://github.com/soedinglab/MMseqs2",
              "6f45232ac8daca14e354ae320a4359056ec524c2"),
    DirectorySource("./bundled")
]

script = raw"""
cd $WORKSPACE/srcdir/MMseqs2*/

# patch CMakeLists.txt so it doesn't set -march unnecessarily on ARM
atomic_patch -p1 ../patches/arm-simd-march-cmakefile.patch

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
    -DNATIVE_ARCH=0 ${ARCH_FLAGS}
make -j${nproc}
make install

install_license ../LICENSE.md
"""

platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || arch(p) == "i686")
# expand cxxstring abis on platforms where we use g++
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("mmseqs", :mmseqs)
]

dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="Bzip2_jll")),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"8")
