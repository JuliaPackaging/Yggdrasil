# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MDAL"
version = v"0.9.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lutraconsulting/MDAL.git",
              "46c7de5f64cd4bbb4aef9dfc2352923b0e608c4b"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/MDAL-*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/rename-findsqlite-library.patch

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_BUILD_TYPE=Release
-DENABLE_TESTS=OFF
-DENABLE_COVERAGE=OFF
-DWITH_GDAL=ON
-DWITH_XML=ON
-DWITH_SQLITE3=ON
-DBUILD_STATIC=OFF
-DBUILD_SHARED=ON
-DBUILD_TOOLS=ON
-DBUILD_EXTERNAL_DRIVERS=OFF)

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

cmake . ${CMAKE_FLAGS[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libmdal", :libmdal)
    ExecutableProduct("mdal_translate", :mdal_translate_path)
    ExecutableProduct("mdalinfo", :mdalinfo_path)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"))
    # Updating to a newer HDF5 version is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="HDF5_jll", uuid="0234f1f7-429e-5d53-9886-15a909be8d59"); compat="~1.12")
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"); compat="~2.13.6")
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8"))
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"); compat="400.902.5")
]

# Build the tarballs, and possibly a `build.jl` as well.
# GDAL uses a preferred of 7 so match that
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
