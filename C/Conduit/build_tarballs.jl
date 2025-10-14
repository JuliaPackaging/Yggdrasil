# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "Conduit"
version = v"0.9.5"
sources = [
    ArchiveSource("https://github.com/LLNL/conduit/releases/download/v$(version)/conduit-v$(version)-src-with-blt.tar.gz",
		  "d93294efbf0936da5a27941e13486aa1a04a74a59285786a2303eed19a24265a"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/conduit*

# Provide C wrapper for some functions that generate example output, to make them callable from Julia
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/blueprint_mesh_examples_generate.patch

options=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DBUILD_SHARED_LIBS=ON
    -DENABLE_TESTS=OFF
    -DENABLE_EXAMPLES=OFF
    -DENABLE_UTILS=ON
    -DENABLE_DOCS=OFF
    -DENABLE_RELAY_WEBSERVER=OFF
    -DENABLE_COVERAGE=OFF
    -DENABLE_PYTHON=OFF
    -DENABLE_FORTRAN=OFF
    -DENABLE_OPENMP=ON
    -DCONDUIT_ENABLE_TESTS=OFF
    -DHDF5_DIR=${prefix}
    -DZFP_DIR=${prefix}
    -DZLIB_DIR=${prefix}
)
if [[ ${target} == i686*-mingw* ]]; then
    # Conduit has build errors with MicrosoftMPI on 32-bit Intel, disable it
    options+=(-DENABLE_MPI=OFF)
else
    options+=(-DENABLE_MPI=ON)
fi

cmake -Bbuild "${options[@]}" src
cmake --build build --parallel ${nproc}
cmake --install build
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_cxxstring_abis(supported_platforms())

platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    ExecutableProduct("conduit_adjset_validate", :conduit_adjset_validate),
    ExecutableProduct("conduit_blueprint_verify", :conduit_blueprint_verify),
    ExecutableProduct("conduit_generate_data", :conduit_generate_data),
    ExecutableProduct("conduit_relay_io_convert", :conduit_relay_io_convert),
    ExecutableProduct("conduit_relay_io_ls", :conduit_relay_io_ls),
    LibraryProduct("libconduit", :libconduit),
    LibraryProduct("libconduit_blueprint", :libconduit_blueprint),
    LibraryProduct("libconduit_relay", :libconduit_relay),
]

# We could additionally depend on
# - ADIOS1 (not an Yggdrasil package)
# - ADIOS2 (not yet supported by Conduit)
# - Silo (not an Yggdrasil package)
# - Parmetis
# - Python

dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="HDF5_jll"); compat="~1.14.6"),
    Dependency(PackageSpec(name="Zlib_jll"); compat="1.2.12"),
    Dependency(PackageSpec(name="zfp_jll"); compat="1.0.2"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
	       augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"5")
