# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "Silo"
version = v"4.12.0"
sources = [
    ArchiveSource("https://github.com/LLNL/Silo/releases/download/$(version)/Silo-$(version).tar.xz",
                  "bde1685e4547d5dd7416bd6215b41f837efef0e4934d938ba776957afbebdff0"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/Silo*

# Correct HDF5 compatibility
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/505.patch

# Correct Windows support
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/windows.patch

# Do not run target exectutables at build time
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/pdb_detect.patch

# We cannot enable hzip nor fpzip because these are not BSD licensed
cmake_options=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DSILO_BUILD_FOR_BSD_LICENSE=ON
    -DSILO_ENABLE_BROWSER=OFF
    -DSILO_ENABLE_FORTRAN=OFF
    -DSILO_ENABLE_HDF5=ON
    -DSILO_ENABLE_JSON=ON
    -DSILO_ENABLE_PYTHON_MODULE=OFF
    -DSILO_ENABLE_SHARED=ON
    -DSILO_ENABLE_SILEX=OFF
    -DSILO_ENABLE_SILOCK=ON
    -DSILO_ENABLE_TESTS=OFF
    -DSILO_HDF5_SZIP_DIR=${prefix}
)

cmake -Bbuild ${cmake_options[@]}

# Provide generated header file
case ${target} in
    arm-*|armv7l-*|i686-*) cp ${WORKSPACE}/srcdir/files/pdform-le32.h build/include/pdform.h;;
    aarch64-*|powerpc64le-*|riscv64-*|x86_64-*) cp ${WORKSPACE}/srcdir/files/pdform-le64.h build/include/pdform.h;;
    *) exit 1;;
esac

cmake --build build --parallel ${nproc}
cmake --install build

install_license COPYRIGHT
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = expand_cxxstring_abis(supported_platforms())
platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    LibraryProduct(["libsiloh5", "libsilo"], :libsilo),
]

dependencies = [
    Dependency("HDF5_jll"; compat="2.0.0"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# We need to use at least GCC 8 to ensure that we get at least libgfortran5, which we need for HDF5.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"8")
