# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "RichDEM"
version = v"2.3.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://github.com/Cervest/richdem/releases/download/v$(version)/richdem-$(version).zip",
        "7f6ae065f92847d0a4bd17c9bbc689e03417ecfc78afc1bd0d4792f434ec0c47",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/richdem-*
mkdir build && cd build

cmake \
    -DJulia_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DJlCxx_DIR=$prefix/lib/cmake/JlCxx \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_GDAL=ON ../. 

# NetCDF is the most restrictive dependency as far as platform availability, so we'll use it where applicable but disable it otherwise
if ! find ${libdir} -name "libnetcdf*.${dlext}" -exec false '{}' +; then
    CMAKE_FLAGS+=(-DWITH_NETCDF=ON)
else
    echo "Disabling NetCDF support"
    CMAKE_FLAGS+=(-DWITH_NETCDF=OFF)
fi
# HDF5 is also a restrictive dependency as far as platform availability, so we'll use it where applicable but disable it otherwise
if ! find ${libdir} -name "libhdf5*.${dlext}" -exec false '{}' +; then
    CMAKE_FLAGS+=(-DWITH_HDF5=ON)
else
    echo "Disabling HDF5 support"
    CMAKE_FLAGS+=(-DWITH_HDF5=OFF)
fi
if [[ "${target}" == x86_64-linux-musl* ]]; then
    export LDFLAGS="$LDFLAGS -lcurl"  # same fix as used for PROJ
    rm /usr/lib/libexpat.so.1  # ugly, but can't figure out CMake behaviour here
fi

VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc} 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]
julia_compat = join(
    "~" .* string.(getfield.(julia_versions, :major)) .* "." .*
    string.(getfield.(julia_versions, :minor)),
    ", ",
)

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platformfilter(p) = (arch(p) != "armv6l" && !Sys.isbsd(p))
platforms = filter(platformfilter, platforms)
platforms = expand_cxxstring_abis(platforms)

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
        );
        platforms = filter(!Sys.isbsd, platforms),
    )
    Dependency(
        PackageSpec(name = "LLVMOpenMP_jll", uuid = "1d63c593-3942-5779-bab2-d838dc0a180e");
        platforms = filter(Sys.isbsd, platforms),
    )
    BuildDependency(
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
        compat = "=1.76.0",
    )
    Dependency(
        PackageSpec(name = "GDAL_jll", uuid = "a7073274-a066-55f0-b90d-d619367d196c");
        compat = "=300.202.100",
    )
    # Updating to a newer HDF5 version is likely possible without problems but requires rebuilding this package
    Dependency(
        PackageSpec(name = "HDF5_jll", uuid = "0234f1f7-429e-5d53-9886-15a909be8d59");
        compat = "~1.12",
    )
    Dependency(
        PackageSpec(name = "NetCDF_jll", uuid = "7243133f-43d8-5620-bbf4-c2c921802cf3");
        compat = "400.902.5",
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
    julia_compat = julia_compat,
    preferred_gcc_version = v"10.2.0",
)
