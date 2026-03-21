# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "mpifileutils"
version = v"0.12.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/hpc/mpifileutils", "db315cf72cb52fb48b688fcef9fbeac1121f6ee4"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mpifileutils

atomic_patch -p1 ../patches/mpi.patch

xattrs=ON
if [[ $target = *apple* || $target = *freebsd* ]]; then
   # libattr is not available
   xattrs=OFF
fi

cmake_options=(
    -Bbuild
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_FIND_ROOT_PATH=${prefix}
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_PREFIX_PATH=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DMPI_HOME=${prefix}
    -DENABLE_DAOS=OFF
    -DENABLE_EXPERIMENTAL=OFF
    -DENABLE_GPFS=OFF
    -DENABLE_HDF5=OFF           # requires HDF5
    -DENABLE_HPFS=OFF
    -DENABLE_LIBARCHIVE=ON
    -DENABLE_XATTRS=${xattrs}   # requires libattr
)
export MPITRAMPOLINE_CC="${CC}"
export MPITRAMPOLINE_CXX="${CXX}"
export MPITRAMPOLINE_FC="${FC}"

cmake "${cmake_options[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# <byteswap.h> is required
filter!(!Sys.isapple, platforms)
# <sys/sysinfo.h> is required
filter!(!Sys.isfreebsd, platforms)
# MPI isn't working well on Windows
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmfu", :libmfu),
    ExecutableProduct("dbcast", :dbcast),
    ExecutableProduct("dbz2", :dbz2),
    ExecutableProduct("dchmod", :dchmod),
    ExecutableProduct("dcmp", :dcmp),
    ExecutableProduct("dcp", :dcp),
    ExecutableProduct("dcp1", :dcp1),
    ExecutableProduct("ddup", :ddup),
    ExecutableProduct("dfilemaker", :dfilemaker),
    ExecutableProduct("dfind", :dfind),
    ExecutableProduct("dreln", :dreln),
    ExecutableProduct("drm", :drm),
    ExecutableProduct("dstripe", :dstripe),
    ExecutableProduct("dsync", :dsync),
    ExecutableProduct("dtar", :dtar),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    #TODO # To ensure that the correct version of libgfortran is found at runtime
    #TODO Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("Attr_jll"; compat="2.5.3"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("LibArchive_jll"; compat="3.7.9"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("dtcmp_jll"; compat="1.1.6"),
    Dependency("libcap_jll"; compat="2.76"),
    Dependency("libcircle_jll"; compat="0.3"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"5")
