# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HHsuite"
version = v"3.3.0"

# TODO
# - MPI support

sources = [
    ArchiveSource("https://github.com/soedinglab/hh-suite/archive/refs/tags/v$(version).tar.gz",
                  "dd67f7f3bf601e48c9c0bc4cf1fbe3b946f787a808bde765e9436a48d27b0964"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/hh-suite-*/

# patch CMakeLists.txt so it doesn't set -march unnecessarily on ARM
atomic_patch -p1 ../patches/arm-simd-march-cmakefile.patch

# macos: use gcc/g++ so we can use openmp
if [[ "${target}" == *-apple-darwin* ]]; then
    CMAKE_TARGET_TOOLCHAIN="${CMAKE_TARGET_TOOLCHAIN/%.cmake/_gcc.cmake}"
    echo "[INFO] setting CMAKE_TARGET_TOOLCHAIN = ${CMAKE_TARGET_TOOLCHAIN}"
fi

arch_opts=
if [[ ${target} == x86_64-* ]]; then
    arch_opts="-DHAVE_SSE2=ON -DHAVE_SSE4_1=ON -DHAVE_AVX2=ON"
elif [[ ${target} == aarch64-* ]]; then
    arch_opts="-DHAVE_ARM8=ON"
elif [[ ${target} == powerpc64le-* ]]; then
    arch_opts="-DHAVE_POWER8=ON -DHAVE_POWER9=ON"
fi

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DNATIVE_ARCH=OFF \
    ${arch_opts}
make -j${nproc}
make install

install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Build failures
# - x86_64-w64-mingw32
#   fatal error: err.h: No such file or directory
# - powerpc64le-linux-gnu
#   build tries to use x86 vector instructions
#
platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || arch(p) == "powerpc64le")
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("a3m_database_extract", :a3m_database_extract), 
    ExecutableProduct("a3m_database_filter", :a3m_database_filter), 
    ExecutableProduct("a3m_database_reduce", :a3m_database_reduce), 
    ExecutableProduct("a3m_extract", :a3m_extract), 
    ExecutableProduct("a3m_reduce", :a3m_reduce), 
    ExecutableProduct("cstranslate", :cstranslate), 
    ExecutableProduct("ffindex_apply", :ffindex_apply), 
    ExecutableProduct("ffindex_build", :ffindex_build), 
    ExecutableProduct("ffindex_from_fasta", :ffindex_from_fasta), 
    ExecutableProduct("ffindex_from_fasta_with_split", :ffindex_from_fasta_with_split), 
    ExecutableProduct("ffindex_get", :ffindex_get), 
    ExecutableProduct("ffindex_modify", :ffindex_modify), 
    ExecutableProduct("ffindex_order", :ffindex_order), 
    ExecutableProduct("ffindex_reduce", :ffindex_reduce), 
    ExecutableProduct("ffindex_unpack", :ffindex_unpack), 
    ExecutableProduct("hhalign", :hhalign), 
    ExecutableProduct("hhalign_omp", :hhalign_omp), 
    ExecutableProduct("hhblits", :hhblits), 
    ExecutableProduct("hhblits_ca3m", :hhblits_ca3m), 
    ExecutableProduct("hhblits_omp", :hhblits_omp), 
    ExecutableProduct("hhconsensus", :hhconsensus), 
    ExecutableProduct("hhfilter", :hhfilter), 
    ExecutableProduct("hhmake", :hhmake), 
    ExecutableProduct("hhsearch", :hhsearch), 
    ExecutableProduct("hhsearch_omp", :hhsearch_omp),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"7")
