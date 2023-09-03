# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCIP_SDP"

version = v"400.200.0"

sources = [
    ArchiveSource("https://www.opt.tu-darmstadt.de/scipsdp/downloads/scipsdp-4.2.0.tgz", "40e2823c9edcbbac6b047d8f3d54594029b7d742d8e8bc3a8f87552cc5b479ec"),
]

# Bash recipe for building across all platforms
script = raw"""
cd scipsdp*

mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
  -DCMAKE_BUILD_TYPE=Release\
  -DSDPS=sdpa\
  -DSDPA_INCLUDE_DIRS=${includedir}\
  -DSCIP_INCLUDE_DIRS=${includedir}\
  -DSCIP_DIR=${prefix}\
  -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
  -DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}" \
  ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(expand_cxxstring_abis(supported_platforms(; experimental=true)))

# The products that we will ensure are always built
products = [
    LibraryProduct("libscipsdp", :libscipsdp),
]

dependencies = [
    Dependency(PackageSpec(name="MUMPS_jll", uuid="ca64183c-ec4f-5579-95d5-17e128c21291")),
    Dependency(PackageSpec(name="SDPA_jll", uuid="7fc90fd6-dbef-5a6a-93f8-169f2a2e705b")),
    Dependency(PackageSpec(name="SCIP_PaPILO_jll", uuid="fc9abe76-a5e6-5fed-b0b7-a12f309cf031")),
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
    preferred_gcc_version=v"7",
    julia_compat="1.6",
)
