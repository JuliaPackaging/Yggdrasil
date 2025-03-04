# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HDF5"
version = v"1.14.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://support.hdfgroup.org/releases/hdf5/v$(version.major)_$(version.minor)/v$(version.major)_$(version.minor)_$(version.patch)/downloads/hdf5-$version.tar.gz",
                  "e4defbac30f50d64e1556374aa49e574417c9e72c6b1de7a4ff88c4b1bea6e9b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/hdf5-*

atomic_patch -p1 ../patches/cmake-fortran.patch
atomic_patch -p1 ../patches/mpi.patch

if [[ ${target} == *-mingw* ]]; then
    cp ../headers/pthread_time.h "/opt/${target}/${target}/sys-root/include/pthread_time.h"
fi

cmake_options=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_EXE_LINKER_FLAGS="-L${libdir} -lsz"      # help cmake link against the sz library
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_SHARED_LINKER_FLAGS="-L${libdir} -lsz"   # help cmake link against the sz library
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DMPI_HOME=${prefix}
    -DALLOW_UNSUPPORTED=ON
    -DBUILD_TESTING=OFF
    -DHDF5_BUILD_CPP_LIB=ON
    -DHDF5_BUILD_DOC=OFF
    -DHDF5_BUILD_EXAMPLES=OFF
    -DHDF5_BUILD_FORTRAN=ON
    -DHDF5_BUILD_HL_LIB=ON
    -DHDF5_BUILD_JAVA=OFF              # would require Java
    -DHDF5_BUILD_PARALLEL_TOOLS=OFF    # would require MFU (<https://github.com/hpc/mpifileutils>?)
    -DHDF5_BUILD_TOOLS=ON
    -DHDF5_ENABLE_HDFS=OFF             # would require Java
    -DHDF5_ENABLE_MAP_API=ON
    -DHDF5_ENABLE_PLUGIN_SUPPORT=OFF   # would require PLUGIN
    -DHDF5_ENABLE_ROS3_VFD=ON
    -DHDF5_ENABLE_SZIP_SUPPORT=ON
    -DHDF5_USE_LIBAEC_STATIC=OFF
    -DHDF5_ENABLE_THREADSAFE=ON
    -DHDF5_ENABLE_Z_LIB_SUPPORT=ON
    -DONLY_SHARED_LIBS=ON
)
# Help cmake find the sz library
cp ${prefix}/cmake/libaec-config.cmake ${prefix}/cmake/szip-config.cmake

if [[ ${target} == *darwin* || ${target} == *mingw* ]]; then
    cmake_options+=(-DHDF5_ENABLE_DIRECT_VFD=OFF)
else
    cmake_options+=(-DHDF5_ENABLE_DIRECT_VFD=ON)
fi

if [[ ${target} == *mingw* ]]; then
    cmake_options+=(-DHDF5_ENABLE_MIRROR_VFD=OFF)
    cmake_options+=(-DHDF5_USE_LIBAEC_STATIC=OFF)
else
    cmake_options+=(-DHDF5_ENABLE_MIRROR_VFD=ON)
fi

if [[ ${target} == *mingw* ]]; then
    cmake_options+=(-DHDF5_ENABLE_PARALLEL=OFF)
else
    cmake_options+=(-DHDF5_ENABLE_PARALLEL=ON)
fi

if [[ ${target} == *mingw* || ${target} == *freebsd* ]]; then
    cmake_options+=(-DHDF5_ENABLE_SUBFILING_VFD=OFF)
else
    cmake_options+=(-DHDF5_ENABLE_SUBFILING_VFD=ON)
fi

export MPITRAMPOLINE_CC="${CC}"
export MPITRAMPOLINE_CXX="${CXX}"
export MPITRAMPOLINE_FC="${FC}"

mkdir saved
case ${target} in
    aarch64-apple-darwin*)
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,16;33;5;3;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/darwin-arm64v8/* saved
        ;;
    aarch64-linux-*)
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,16;33;5;3;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/debian-arm64v8/* saved
        ;;
    aarch64-*-freebsd*)
        # Probably the same as x86_64-*-freebsd but without real*10
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,16;33;5;3;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/freebsd-arm64v8/* saved
        ;;
    arm-linux-*)
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8;4,8;15;4;2;4;1,2,4,8;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/debian-arm32v7/* saved
        ;;
    i686-linux-*)
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8;4,8,12,16;33;4;4;4;1,2,4,8;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_12=12
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/debian-i386/* saved
        ;;
    i686-w64-mingw32)
        # sizeof(long double) == 12
        # layout seems to be 16-bit sign+exponent and 64-bit mantissa
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8;4,8,12,16;33;4;4;4;1,2,4,8;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_12=12
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/msys2-mingw32/* saved
        ;;
    powerpc64le-linux-*)
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,16;33;5;3;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/debian-ppc64le/* saved
        ;;
    riscv64-linux-*)
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,16;33;5;3;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/debian-riscv64/* saved
        ;;
    x86_64-apple-darwin*)
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,10,16;33;5;4;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_10=16
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/darwin-amd64/* saved
        ;;
    x86_64-linux-*)
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,10,16;33;5;4;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_10=16
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/debian-amd64/* saved
        ;;
    x86_64-*-freebsd*)
        # no __float128
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,10,16;33;5;4;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_10=16
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/freebsd-amd64/* saved
        ;;
    x86_64-w64-mingw32)
        # sizeof(long double) == 16
        # layout seems to be 16-bit sign+exponent and 64-bit mantissa
        cmake_options+=(
            -DFC_AVAIL_KINDS_RESULT='1,2,4,8,16;4,8,10,16;33;5;4;5;1,2,4,8,16;'
            -DVALIDINTKINDS_RESULT_1=1
            -DVALIDINTKINDS_RESULT_2=2
            -DVALIDINTKINDS_RESULT_4=4
            -DVALIDINTKINDS_RESULT_8=8
            -DVALIDINTKINDS_RESULT_16=16
            -DVALIDREALKINDS_RESULT_4=4
            -DVALIDREALKINDS_RESULT_8=8
            -DVALIDREALKINDS_RESULT_10=16
            -DVALIDREALKINDS_RESULT_16=16
            -DPAC_SIZEOF_NATIVE_KINDS_RESULT='4;4;4;4;8;8;'
        )
        cp ../files/msys2-mingw64/* saved
        ;;
    *)
        echo "Unsupported target architecture ${target}" >&2
        exit 1
        ;;
esac

cmake -B builddir "${cmake_options[@]}"
cmake --build builddir --parallel ${nproc}
cmake --install builddir

install_license COPYING

# Clean up: We created the file, we need to remove it
rm ${prefix}/cmake/szip-config.cmake
rm -f "/opt/${target}/${target}/sys-root/include/pthread_time.h"
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=x->!Sys.iswindows(x))
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# Our riscv64 work-arounds are broken for MPI:
# `riscv64-linux-gnu-libgfortran5-cxx11-mpi+mpitrampoline` is not an officially supported platform
filter!(p -> arch(p) != "riscv64", platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.5.1", OpenMPI_compat="4.1.6, 5")

# Avoid platforms where the MPI implementation isn't supported
filter!(platforms) do p
    if p["mpi"] == "mpich"
        arch(p) == "riscv64" && return false
    elseif p["mpi"] == "mpitrampoline"
        libc(p) == "musl" && return false
    elseif p["mpi"] == "openmpi"
        arch(p) == "armv6l" && libc(p) == "glibc" && return false
        Sys.isfreebsd(p) && arch(p) == "aarch64" && return false # we should build this
        arch(p) == "riscv64" && return false                     # we should build this at some time
    end
    return true
end

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
    # To ensure that the correct version of libgfortran is found at runtime
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Zlib_jll"),
    # Dependency("dlfcn_win32_jll"; platforms=filter(Sys.iswindows, platforms)),
    Dependency("libaec_jll"),   # This is the successor of szlib
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
