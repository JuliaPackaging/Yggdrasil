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
  -DSDPS=dsdp\
  -DDSDP_INCLUDE_DIRS=${includedir}\
  -DSCIP_INCLUDE_DIRS=${includedir}\
  -DSCIP_DIR=${prefix}\
  -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
  -DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}" \
  ..
make -j${nproc}
make install
"""

platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libscipsdp", :libscipsdp),
]

dependencies = [
    Dependency(PackageSpec(name="bliss_jll", uuid="508c9074-7a14-5c94-9582-3d4bc1871065")),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d")),
    Dependency(PackageSpec(name="MUMPS_jll", uuid="ca64183c-ec4f-5579-95d5-17e128c21291")),
    Dependency(PackageSpec(name="DSDP_jll", uuid="1065e140-e56c-5613-be8b-7480bf7138df")),
    Dependency(PackageSpec(name="Ipopt_jll", uuid="9cc047cb-c261-5740-88fc-0cf96f7bdcc7"); compat="300.1400.1302"),
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="SCIP_jll", uuid="e5ac4fe4-a920-5659-9bf8-f9f73e9e79ce")),
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
