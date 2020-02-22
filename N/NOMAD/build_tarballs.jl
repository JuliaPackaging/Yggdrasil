using BinaryBuilder

name = "NOMAD"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gist.github.com/amontoison/06dac8b63424854f754264597af6b09e/raw/8ab9aa6cb54b5491bc4f46977b086ff17bdd2ba8/NOMAD.zip", "84c0f2a01928b8d2c68303709e74173a296d39b014810c658b43662a6a3f93a1"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd "${WORKSPACE}/srcdir/NOMAD"
if [[ "${target}" == *-musl* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/include_sys_time_missing_timeval_musl.patch"
fi
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
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
    LibraryProduct("libsgtelib", :libsgtelib)

]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
