# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HDF5"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/HDFGroup/hdf5/releases/download/$(version)/hdf5-$(version).tar.gz",
                  "f4c2edc5668fb846627182708dbe1e16c60c467e63177a75b0b9f12c19d7efed"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/hdf5*

# Make our own, more modern cmake visible
apk del cmake

if [[ ${bb_full_target} == *mpitrampoline* ]]; then
    atomic_patch -p1 ../patches/mpi.patch
fi

# OS does not support `O_DIRECT`
direct_vfd=$(if [[ ${target} == *-apple-* || ${target} == *-w64-* ]]; then echo OFF; else echo ON; fi)

# `aws_c_s3_jll` has not been built
ros3_vdf=$(if [[ ${target} == i686-w64-* ]]; then echo OFF; else echo ON; fi)

# MPI does not support Fortran
parallel=$(if [[ ${target} == *-w64-* ]]; then echo OFF; else echo ON; fi)

cmake_options=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_STATIC_LIBS=OFF
    -DBUILD_TESTING=OFF
    -DHDF5_ALLOW_UNSUPPORTED=ON
    -DHDF5_BUILD_CPP_LIB=ON
    -DHDF5_BUILD_DOC=OFF
    -DHDF5_BUILD_EXAMPLES=OFF
    -DHDF5_BUILD_FORTRAN=ON
    -DHDF5_BUILD_HL_LIB=ON
    -DHDF5_BUILD_JAVA=OFF              # would require Java
    -DHDF5_BUILD_PARALLEL_TOOLS=OFF    # would require MFU (<https://github.com/hpc/mpifileutils>?)
    -DHDF5_BUILD_TOOLS=ON
    -DHDF5_ENABLE_CONCURRENCY=ON       # superset of THREADSAFE
    -DHDF5_ENABLE_DIRECT_VFD=${direct_vfd}
    -DHDF5_ENABLE_HDFS=OFF             # would require Java
    -DHDF5_ENABLE_MAP_API=ON
    -DHDF5_ENABLE_MIRROR_VFD=ON
    -DHDF5_ENABLE_PARALLEL=${parallel}
    -DHDF5_ENABLE_ROS3_VFD=${ros3_vfd}
    -DHDF5_ENABLE_SUBFILING_VFD=ON
    -DHDF5_ENABLE_SZIP_SUPPORT=ON
    -DHDF5_ENABLE_ZLIB_SUPPORT=ON
    -DHDF5_USE_PREGEN=ON
    -DMPI_HOME=${prefix}
)

# We could enable this, but it would require more cross-compiling information:
#     -DHDF5_ENABLE_NONSTANDARD_FEATURE_FLOAT16=ON
# We would need to set these flags (and check that these conditions are true!): 
#     -DH5_FLOAT16_CONVERSION_FUNCS_LINK=ON
#     -DH5_FLOAT16_CONVERSION_FUNCS_LINK_NO_FLAGS=ON
#     -DH5_LDOUBLE_TO_FLOAT16_CORRECT=ON

# We have pregenerated the Fortran configurations for Linux.
# (See <https://github.com/HDFGroup/hdf5/issues/6042>.)
# We assume that Darwin and mingw use the same configurations.
case ${target} in
    aarch64-linux-*|aarch64-apple-darwin*|aarch64-*-freebsd*)
        cmake_options+=(
            -DHDF5_USE_PREGEN_DIR=${WORKSPACE}/srcdir/files/debian-arm64v8
            -DPAC_FORTRAN_NUM_INTEGER_KINDS=5
            -DPAC_FC_ALL_INTEGER_KINDS='{1,2,4,8,16}'
            -DPAC_FC_ALL_INTEGER_KINDS_SIZEOF='{1,2,4,8,16}'
            -DPAC_FORTRAN_NUM_LOGICAL_KINDS=5
            -DPAC_FC_ALL_LOGICAL_KINDS='{1,2,4,8,16}'
            -DPAC_FORTRAN_NUM_REAL_KINDS=3
            -DPAC_FC_ALL_REAL_KINDS='{4,8,16}'
            -DPAC_FC_ALL_REAL_KINDS_SIZEOF='{4,8,16}'
            -DH5_PAC_FC_MAX_REAL_PRECISION=33
            -DPAC_FORTRAN_NATIVE_INTEGER_KIND=4
            -DPAC_FORTRAN_NATIVE_INTEGER_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_REAL_KIND=4
            -DPAC_FORTRAN_NATIVE_REAL_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_DOUBLE_KIND=8
            -DPAC_FORTRAN_NATIVE_DOUBLE_SIZEOF=8
            -DH5_H5CONFIG_F_NUM_IKIND='INTEGER, PARAMETER :: num_ikinds = 5'
            -DH5_H5CONFIG_F_IKIND='INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8,16/)'
        )
        ;;
    arm-linux-*)
        cmake_options+=(
            -DHDF5_USE_PREGEN_DIR=${WORKSPACE}/srcdir/files/debian-arm32v7
            -DPAC_FORTRAN_NUM_INTEGER_KINDS=4
            -DPAC_FC_ALL_INTEGER_KINDS='{1,2,4,8}'
            -DPAC_FC_ALL_INTEGER_KINDS_SIZEOF='{1,2,4,8}'
            -DPAC_FORTRAN_NUM_LOGICAL_KINDS=4
            -DPAC_FC_ALL_LOGICAL_KINDS='{1,2,4,8}'
            -DPAC_FORTRAN_NUM_REAL_KINDS=2
            -DPAC_FC_ALL_REAL_KINDS='{4,8}'
            -DPAC_FC_ALL_REAL_KINDS_SIZEOF='{4,8}'
            -DH5_PAC_FC_MAX_REAL_PRECISION=15
            -DPAC_FORTRAN_NATIVE_INTEGER_KIND=4
            -DPAC_FORTRAN_NATIVE_INTEGER_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_REAL_KIND=4
            -DPAC_FORTRAN_NATIVE_REAL_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_DOUBLE_KIND=8
            -DPAC_FORTRAN_NATIVE_DOUBLE_SIZEOF=8
            -DH5_H5CONFIG_F_NUM_IKIND='INTEGER, PARAMETER :: num_ikinds = 4'
            -DH5_H5CONFIG_F_IKIND='INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8/)'
        )
        ;;
    i686-linux-*|i686-w64-mingw32)
        cmake_options+=(
            -DHDF5_USE_PREGEN_DIR=${WORKSPACE}/srcdir/files/debian-i386
            -DPAC_FORTRAN_NUM_INTEGER_KINDS=4
            -DPAC_FC_ALL_INTEGER_KINDS='{1,2,4,8}'
            -DPAC_FC_ALL_INTEGER_KINDS_SIZEOF='{1,2,4,8}'
            -DPAC_FORTRAN_NUM_LOGICAL_KINDS=4
            -DPAC_FC_ALL_LOGICAL_KINDS='{1,2,4,8}'
            -DPAC_FORTRAN_NUM_REAL_KINDS=3
            -DPAC_FC_ALL_REAL_KINDS='{4,8,10}'
            -DPAC_FC_ALL_REAL_KINDS_SIZEOF='{4,8,12}'
            -DH5_PAC_FC_MAX_REAL_PRECISION=18
            -DPAC_FORTRAN_NATIVE_INTEGER_KIND=4
            -DPAC_FORTRAN_NATIVE_INTEGER_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_REAL_KIND=4
            -DPAC_FORTRAN_NATIVE_REAL_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_DOUBLE_KIND=8
            -DPAC_FORTRAN_NATIVE_DOUBLE_SIZEOF=8
            -DH5_H5CONFIG_F_NUM_IKIND='INTEGER, PARAMETER :: num_ikinds = 4'
            -DH5_H5CONFIG_F_IKIND='INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8/)'
        )
        ;;
    powerpc64le-linux-*)
        cmake_options+=(
            -DHDF5_USE_PREGEN_DIR=${WORKSPACE}/srcdir/files/debian-ppc64le
            -DPAC_FORTRAN_NUM_INTEGER_KINDS=5
            -DPAC_FC_ALL_INTEGER_KINDS='{1,2,4,8,16}'
            -DPAC_FC_ALL_INTEGER_KINDS_SIZEOF='{1,2,4,8,16}'
            -DPAC_FORTRAN_NUM_LOGICAL_KINDS=5
            -DPAC_FC_ALL_LOGICAL_KINDS='{1,2,4,8,16}'
            -DPAC_FORTRAN_NUM_REAL_KINDS=3
            -DPAC_FC_ALL_REAL_KINDS='{4,8,16}'
            -DPAC_FC_ALL_REAL_KINDS_SIZEOF='{4,8,16}'
            -DH5_PAC_FC_MAX_REAL_PRECISION=33
            -DPAC_FORTRAN_NATIVE_INTEGER_KIND=4
            -DPAC_FORTRAN_NATIVE_INTEGER_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_REAL_KIND=4
            -DPAC_FORTRAN_NATIVE_REAL_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_DOUBLE_KIND=8
            -DPAC_FORTRAN_NATIVE_DOUBLE_SIZEOF=8
            -DH5_H5CONFIG_F_NUM_IKIND='INTEGER, PARAMETER :: num_ikinds = 5'
            -DH5_H5CONFIG_F_IKIND='INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8,16/)'
        )
        ;;
    riscv64-linux-*)
        cmake_options+=(
            -DHDF5_USE_PREGEN_DIR=${WORKSPACE}/srcdir/files/debian-riscv64
            -DPAC_FORTRAN_NUM_INTEGER_KINDS=5
            -DPAC_FC_ALL_INTEGER_KINDS='{1,2,4,8,16}'
            -DPAC_FC_ALL_INTEGER_KINDS_SIZEOF='{1,2,4,8,16}'
            -DPAC_FORTRAN_NUM_LOGICAL_KINDS=5
            -DPAC_FC_ALL_LOGICAL_KINDS='{1,2,4,8,16}'
            -DPAC_FORTRAN_NUM_REAL_KINDS=3
            -DPAC_FC_ALL_REAL_KINDS='{4,8,16}'
            -DPAC_FC_ALL_REAL_KINDS_SIZEOF='{4,8,16}'
            -DH5_PAC_FC_MAX_REAL_PRECISION=33
            -DPAC_FORTRAN_NATIVE_INTEGER_KIND=4
            -DPAC_FORTRAN_NATIVE_INTEGER_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_REAL_KIND=4
            -DPAC_FORTRAN_NATIVE_REAL_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_DOUBLE_KIND=8
            -DPAC_FORTRAN_NATIVE_DOUBLE_SIZEOF=8
            -DH5_H5CONFIG_F_NUM_IKIND='INTEGER, PARAMETER :: num_ikinds = 5'
            -DH5_H5CONFIG_F_IKIND='INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8,16/)'
        )
        ;;
    x86_64-linux-*|x86_64-apple-darwin*|x86_64-*-freebsd*|x86_64-w64-mingw32)
        cmake_options+=(
            -DHDF5_USE_PREGEN_DIR=${WORKSPACE}/srcdir/files/debian-amd64
            -DPAC_FORTRAN_NUM_INTEGER_KINDS=5
            -DPAC_FC_ALL_INTEGER_KINDS='{1,2,4,8,16}'
            -DPAC_FC_ALL_INTEGER_KINDS_SIZEOF='{1,2,4,8,16}'
            -DPAC_FORTRAN_NUM_LOGICAL_KINDS=5
            -DPAC_FC_ALL_LOGICAL_KINDS='{1,2,4,8,16}'
            -DPAC_FORTRAN_NUM_REAL_KINDS=4
            -DPAC_FC_ALL_REAL_KINDS='{4,8,10,16}'
            -DPAC_FC_ALL_REAL_KINDS_SIZEOF='{4,8,16,16}'
            -DH5_PAC_FC_MAX_REAL_PRECISION=33
            -DPAC_FORTRAN_NATIVE_INTEGER_KIND=4
            -DPAC_FORTRAN_NATIVE_INTEGER_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_REAL_KIND=4
            -DPAC_FORTRAN_NATIVE_REAL_SIZEOF=4
            -DPAC_FORTRAN_NATIVE_DOUBLE_KIND=8
            -DPAC_FORTRAN_NATIVE_DOUBLE_SIZEOF=8
            -DH5_H5CONFIG_F_NUM_IKIND='INTEGER, PARAMETER :: num_ikinds = 5'
            -DH5_H5CONFIG_F_IKIND='INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8,16/)'
        )
        ;;
    *)
        echo "Unsupported target architecture ${target}" >&2
        exit 1
        ;;
esac

export MPITRAMPOLINE_CC="${CC}"
export MPITRAMPOLINE_CXX="${CXX}"
export MPITRAMPOLINE_FC="${FC}"

cmake -Bbuilddir "${cmake_options[@]}"

# Remove stray `-llibname-NOTFOUND` from `hdf5.pc`:
# (Reported as <https://github.com/HDFGroup/hdf5/issues/6059>)
sed -i -e 's/-llibname-NOTFOUND//g' builddir/CMakeFiles/hdf5.pc

cmake --build builddir --parallel ${nproc}
cmake --install builddir

install_license LICENSE
"""

sources, script = require_macos_sdk("10.14", sources, script)

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    # # HDF5 tools
    ExecutableProduct("h5clear", :h5clear),
    ExecutableProduct("h5copy", :h5copy),
    ExecutableProduct("h5debug", :h5debug),
    ExecutableProduct("h5delete", :h5delete),
    ExecutableProduct("h5diff", :h5diff),
    ExecutableProduct("h5dump", :h5dump),
    ExecutableProduct("h5format_convert", :h5format_convert),
    ExecutableProduct("h5import", :h5import),
    ExecutableProduct("h5jam",:h5jam),
    ExecutableProduct("h5ls", :h5ls),
    ExecutableProduct("h5mkgrp", :h5mkgrp),
    ExecutableProduct("h5perf_serial",:h5perf_serial),
    ExecutableProduct("h5repack", :h5repack),
    ExecutableProduct("h5repart", :h5repart),
    ExecutableProduct("h5stat", :h5stat),
    ExecutableProduct("h5unjam", :h5unjam),
    ExecutableProduct("h5watch", :h5watch),

    # HDF5 libraries
    LibraryProduct("libhdf5", :libhdf5),
    LibraryProduct("libhdf5_cpp", :libhdf5_cpp),
    LibraryProduct("libhdf5_fortran", :libhdf5_fortran),
    LibraryProduct("libhdf5_hl", :libhdf5_hl),
    LibraryProduct("libhdf5_hl_cpp", :libhdf5_hl_cpp),
    LibraryProduct("libhdf5_hl_fortran", :libhdf5_hl_fortran),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),

    # To ensure that the correct version of libgfortran is found at runtime
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("LibCURL_jll"; compat="7.73, 8"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("aws_c_s3_jll"; compat="0.9.2"),
    Dependency("dlfcn_win32_jll"; platforms=filter(Sys.iswindows, platforms)),
    Dependency("libaec_jll"; compat="1.1.4"), # This is the successor of szlib
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
