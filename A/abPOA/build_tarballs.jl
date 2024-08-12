# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "abPOA"
version = v"1.4.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/yangao07/abPOA.git",
        "c6c9dacf92414cd1a358cbd1d28b6f2ca37b30ed",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/abPOA
install_license LICENSE
atomic_patch -p1 ../patches/no_march_native.patch
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON ..
cmake --build . --parallel ${nproc} --target all
cmake --build . --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> arch(p) == "x86_64", supported_platforms(; exclude = Sys.iswindows))

# The products that we will ensure are always built
products = [
    ExecutableProduct("abpoa", :abpoa), 
    LibraryProduct("libabpoa", :libabpoa)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("SIMDe_jll"),
    Dependency(
        PackageSpec(; name = "Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a");
        compat = "1.2.12",
    ),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"6",
)

