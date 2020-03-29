using BinaryBuilder

name = "NOMAD"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gist.github.com/amontoison/06dac8b63424854f754264597af6b09e/raw/942aba554a82800d0c7438288d3da1a827ef2974/NOMAD.zip", "a6653af375be8006e742239af3914ba48034015d57a2be7a07fc14c6ff245d1b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd "${WORKSPACE}/srcdir/NOMAD"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/nomad_openmp.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/sgtelib_openmp.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/cache_corrections.patch"
if [[ "${target}" == *-musl* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/include_sys_time_missing_timeval_musl.patch"
elif [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    CC=gcc
    CXX=g++
fi
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libnomadInterface", :libnomadInterface),
    LibraryProduct("libnomadAlgos", :libnomadAlgos),
    LibraryProduct("libnomadEval", :libnomadEval),
    LibraryProduct("libnomadUtils", :libnomadUtils),
    LibraryProduct("libsgtelib", :libsgtelib),
    ExecutableProduct("nomad", :nomad),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
