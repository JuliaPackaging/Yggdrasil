using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "FUKA"
version_string = "2.3"
version = VersionNumber(version_string)

sources = [
    GitSource("https://bitbucket.org/fukaws/fuka.git", "f8ee3c7795911e1363358bf155c70f649c100fb5";
              tag="v$(version_string)"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/fuka
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/shell_factor-not-constexpr.patch
# Our CMakeLists.txt (see the comment at its top for why we don't use
# upstream's build system) and C interface
cp -rv ${WORKSPACE}/srcdir/files/. .

export MPITRAMPOLINE_CC=${CC} MPITRAMPOLINE_CXX=${CXX} MPITRAMPOLINE_FC=${FC}

if [[ ${target} == *-mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi

cmake_args=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DMPI_HOME=${prefix}
    -DLAPACK_LIBRARIES=${LBT}
)
if [[ ${target} == *-mingw* ]]; then
    # SCALAPACK32_jll installs only its DLL, in ${libdir}
    export LDFLAGS="-L${libdir}"
    cmake_args+=(-DMPI_GUESS_LIBRARY_NAME=MSMPI)
    if [[ ${target} == x86_64-* ]]; then
        cmake_args+=(-DMPI_C_LIBRARIES=msmpi64)
    fi
fi

cmake -B build "${cmake_args[@]}"
cmake --build build --parallel ${nproc}
cmake --install build

install_license COPYING
# Bundled: include/implementation/flat_hash_map.hpp under the Boost Software
# License, whose text comes with boost_jll, and include/EOS/standalone/brent.hh
# under the "GNU LGPL", version unstated
install_license ${prefix}/share/licenses/boost/LICENSE_1_0.txt
install_license /usr/share/licenses/LGPL-3.0+
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_cxxstring_abis(supported_platforms())
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Upstream names the programs of every solver `solve` and `reader`; we prefix them.
codes = ["bbh", "bh", "bhns", "bns", "bns_headon", "ns", "ns_diffrot", "ns_isotropic"]
programs = [["fuka_$(code)_$(program)" for code in codes for program in ["solve", "reader"]];
            "fuka_ns_diffrot_setup_from_iso"]

products = [
    LibraryProduct("libkadath", :libkadath);
    LibraryProduct("libfuka", :libfuka);
    [ExecutableProduct(program, Symbol(program)) for program in programs]
]

dependencies = [
    Dependency("FFTW_jll"; compat="3.3.10"),
    # GSL changes its ABI in minor releases
    Dependency("GSL_jll"; compat="~2.8.1"),
    Dependency("SCALAPACK32_jll"; compat="2.2.302"),
    Dependency("libblastrampoline_jll"; compat="5.4.0"),
    BuildDependency("boost_jll"),
]
append!(dependencies, platform_dependencies)

# Keep MPItrampoline from loading `mpiwrapper.so` when the audit dlopens the products.
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# GCC 9 for std::filesystem
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"9")
