# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "RichDEM"
version = v"2.3.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://github.com/Cervest/richdem/archive/refs/tags/v$(version).zip",
        "6c87d1fa4c417b7f518c3f2964a1688d2e2f74b6b1381270dc38d741ec709db5",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/richdem-*
mkdir build && cd build
cmake -DJulia_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=$prefix -DJlCxx_DIR=$prefix/lib/cmake/JlCxx -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DUSE_GDAL=ON ../. 
cmake --build . --config Release --target install 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libjlrichdem", :libjlrichdem),
    LibraryProduct("librichdem", :librichdem),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(
            name = "CompilerSupportLibraries_jll",
            uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae",
        ),
    )
    Dependency(
        PackageSpec(name = "libjulia_jll", uuid = "5ad3ddd2-0711-543a-b040-befd59781bbf"),
    )
    Dependency(
        PackageSpec(
            name = "libcxxwrap_julia_jll",
            uuid = "3eaa8342-bff7-56a5-9981-c04077f7cee7",
        ),
    )
    Dependency(
        PackageSpec(name = "boost_jll", uuid = "28df3c45-c428-5900-9ff8-a3135698ca75");
        compat="=1.76.0",
    )
    Dependency(
        PackageSpec(name = "GDAL_jll", uuid = "a7073274-a066-55f0-b90d-d619367d196c"),
    )
    Dependency(
        PackageSpec(name = "OpenMPI_jll", uuid = "fe0851c0-eecd-5654-98d4-656369965a5c"),
    )
]

# Build the tarballs, and possibly a `build.jl` as well.
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
    preferred_gcc_version = v"10.2.0",
)
