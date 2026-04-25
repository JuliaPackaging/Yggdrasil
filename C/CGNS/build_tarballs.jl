using BinaryBuilder, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "CGNS"
version = v"4.5.1"

sources = [
    GitSource("https://github.com/CGNS/CGNS.git",
              "bbce5f0ec594ae4d066893370965d3b77136b13c"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/CGNS*

if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl
    rm /usr/lib/libcurl.*
    rm /usr/lib/libnghttp2.*
fi

# We need to build with MPI since our HDF5 uses MPI, and this makes
# CGNS depend explicitly on MPI. Since we're doing that we might as
# well enable the parallel API.

cmake -Bbuild -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCGNS_BUILD_SHARED=ON \
    -DCGNS_ENABLE_PARALLEL=ON
cmake --build build --parallel ${nproc}
cmake --install build

# CGNS always builds a static library. Remove it.
rm -f ${libdir}/libcgns.a
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
    """

platforms = supported_platforms()
platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    LibraryProduct("libcgns", :libcgns),
    ExecutableProduct("cgnscheck", :cgnscheck),
    ExecutableProduct("cgnscompress", :cgnscompress),
    ExecutableProduct("cgnsconvert", :cgnsconvert),
    ExecutableProduct("cgnsdiff", :cgnsdiff),
    ExecutableProduct("cgnslist", :cgnslist),
    ExecutableProduct("cgnsnames", :cgnsnames),
]

dependencies = [
    Dependency("HDF5_jll"; compat="~2.1.1"),
]
append!(dependencies, platform_dependencies)

# We need at least GCC 5 for the HDF5 libraries
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"8")
