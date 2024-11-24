# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QRupdate_ng"
version = v"1.1.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mpimd-csc/qrupdate-ng.git",
              "45e9ccac49c4c7d3211b7fc90671e5ab1fdb2c86"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qrupdate-ng*

apk add wine

mkdir build
cd build/

if [[ "${target}" == *-mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi

cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_MODULE_PATH=${prefix}/lib/cmake \
      -DBLA_VENDOR=$LBT \
      -DBLAS_LIBRARIES="-L${libdir} -l$LBT" \
      -DLAPACK_LIBRARIES="-L${libdir} -l$LBT"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libqrupdate", :libqrupdate)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"8")
