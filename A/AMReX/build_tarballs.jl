# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "AMReX"
version_string = "25.07"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/AMReX-Codes/amrex/releases/download/$(version_string)/amrex-$(version_string).tar.gz",
                  "19b9e5271451c202610f9c6569189c28fc05bcd655d53525df9169efeb5ee66f"),
    FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
               "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/amrex

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    rm -rf /opt/${target}/${target}/sys-root/System
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX10.14.sdk.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX10.14.sdk/System MacOSX10.14.sdk/usr
    export MACOSX_DEPLOYMENT_TARGET=10.14
fi

# Correct HDF5 compiler wrappers
perl -pi -e 's+-I/workspace/srcdir/hdf5-1[.]14[.]./src/H5FDsubfiling++' $(which h5pcc)

if [[ "${target}" == *-apple-* ]]; then
    if grep -q MPICH_NAME ${prefix}/include/mpi.h; then
        # MPICH's pkgconfig file "mpich.pc" lists these options:
        #     Libs:     -framework OpenCL -Wl,-flat_namespace -Wl,-commons,use_dylibs -L${libdir} -lmpi -lpmpi -lm    -lpthread
        #     Cflags:   -I${includedir}
        # cmake doesn't know how to handle the "-framework OpenCL" option
        # and wants to use "-framework" as a stand-alone option. This fails,
        # and cmake concludes that MPI is not available.
        mpiopts="-DMPI_C_ADDITIONAL_INCLUDE_DIRS='' -DMPI_C_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi' -DMPI_CXX_ADDITIONAL_INCLUDE_DIRS='' -DMPI_CXX_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi'"
    fi
elif [[ "${target}" == x86_64-w64-mingw32 ]]; then
    mpiopts="-DMPI_HOME=${prefix} -DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64"
elif [[ "${target}" == *-mingw* ]]; then
    mpiopts="-DMPI_HOME=${prefix} -DMPI_GUESS_LIBRARY_NAME=MSMPI"
else
    mpiopts=
fi

if [[ "${target}" == *-mingw32* ]]; then
    # AMReX requires a parallel HDF5 library
    hdf5opts="-DAMReX_HDF5=OFF"
else
    hdf5opts="-DAMReX_HDF5=ON"
fi

export MPITRAMPOLINE_CC=${CC}
export MPITRAMPOLINE_CXX=${CXX}
export MPITRAMPOLINE_FC=${FC}

cmake \
    -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DAMReX_FORTRAN=ON \
    -DAMReX_MPI=ON \
    -DAMReX_OMP=ON \
    -DAMReX_PARTICLES=ON \
    -DBUILD_SHARED_LIBS=ON \
    ${hdf5opts} \
    ${mpiopts}
cmake --build build --parallel ${nproc}
cmake --install build

if [[ "${target}" == *-mingw* ]]; then
    # Move all shared libraries to `${libdir}`.
    # Ref: <https://github.com/JuliaPackaging/Yggdrasil/issues/7968>.
    mv -v ${prefix}/lib/*.${dlext} ${libdir}/.
fi

install_license LICENSE
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libamrex_3d", :libamrex)
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# AMReX requires C++17 and thus requires at least libgfortran5
platforms = filter(p -> libgfortran_version(p).major ≥ 5, platforms)

# We cannot build with musl since AMReX requires the `fegetexcept` GNU API
platforms = filter(p -> libc(p) ≠ "musl", platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Windows does not supported parallel HDF5
hdf5_platforms = filter(!Sys.iswindows, platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD 
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else. 
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="HDF5_jll"); compat="~1.14.6", platforms=hdf5_platforms),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
# - GCC 4 is too old: AMReX requires C++14, and thus at least GCC 5
# - AMReX requires C++17, and at least GCC 8 to provide the <filesystem> header
# - GCC 8.1.0 suffers from an ICE, so we use GCC 9 instead
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.6", preferred_gcc_version = v"9")
