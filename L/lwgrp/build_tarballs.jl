# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "lwgrp"
version = v"1.0.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/LLNL/lwgrp", "7d8520d79d2a817fe3a8051b323183a8dd37ed2a"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/lwgrp

export MPITRAMPOLINE_CC="${CC}"
export MPITRAMPOLINE_CXX="${CXX}"
export MPITRAMPOLINE_FC="${FC}"

atomic_patch -p1 ../patches/libtoolize.patch
atomic_patch -p1 ../patches/mpi.patch

./autogen.sh
mkdir build
pushd build
if [[ "${target}" == *-mingw* ]]; then
    # There is no mpicc on Windows
    ../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
else
    ../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} CC=mpicc CXX=mpicxx
fi
make -j${nproc}
make install
popd
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The makefile builds only a static library on Windows. (I guess this could be fixed.)
filter!(!Sys.iswindows, platforms)

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
    LibraryProduct("liblwgrp", :liblwgrp),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
