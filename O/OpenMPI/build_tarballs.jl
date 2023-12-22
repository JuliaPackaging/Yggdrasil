using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "OpenMPI"
# Note that OpenMPI 5 is ABI compatible with OpenMPI 4
version = v"5.0.1"
sources = [
    ArchiveSource("https://download.open-mpi.org/release/open-mpi/v$(version.major).$(version.minor)/openmpi-$(version).tar.gz",
                  "15805510d599558aed2ef43770e8a4683b9a6b361d0a91f107cb7c377cfe2bfb"),
    DirectorySource("./bundled"),
]

script = raw"""
################################################################################
# Install OpenMPI
################################################################################

# Enter the funzone
cd ${WORKSPACE}/srcdir/openmpi-*

if [[ "${bb_full_target}" == *-apple-darwin*-libgfortran[45]-* ]]; then
    # See <https://github.com/JuliaPackaging/Yggdrasil/issues/7745>:
    # Remove the new fancy linkers which don't work yet
    rm /opt/bin/${bb_full_target}/ld64.lld
    rm /opt/bin/${bb_full_target}/ld64.${target}
    rm /opt/bin/${bb_full_target}/${target}-ld64.lld
    rm /opt/${MACHTYPE}/bin/ld64.lld
fi

# Autotools doesn't add `${includedir}` as an include directory on some platforms
export CPPFLAGS="-I${includedir}"

# The configure scripts doesn't link against `libdl` by itself on many platforms
export LIBS='-ldl'

# We use `--enable-script-wrapper-compilers` to turn the compiler
# wrappers (`mpicc` etc.) into scripts instead of binaries. As scripts,
# they can be run in a cross-compiling environment, and cmake can
# infer the MPI options. Otherwise, the MPI options need to be
# specified manually for OpenMPI to work.

./configure \
    --build=${MACHTYPE} \
    --enable-mpi-fortran=usempif08 \
    --enable-script-wrapper-compilers \
    --enable-shared=yes \
    --enable-static=no \
    --host=${target} \
    --prefix=${prefix} \
    --with-cross=${WORKSPACE}/srcdir/${target} \
    --without-cs-fs

# Build the library
make -j${nproc}

# Install the library
make install

################################################################################
# Install licenses
################################################################################

install_license $WORKSPACE/srcdir/openmpi*/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()
# OpenMPI 5 supports only 64-bit systems
filter!(p -> nbits(p) == 64, platforms)
# Disable FreeBSD, it is not supported by PMIx (which we need)
filter!(!Sys.isfreebsd, platforms)
# Disable Windows, we do not know how to cross-compile
filter!(!Sys.iswindows, platforms)

platforms = expand_gfortran_versions(platforms)

# Add `mpi+openmpi` platform tag
foreach(p -> (p["mpi"] = "OpenMPI"), platforms)

products = [
    # OpenMPI
    LibraryProduct("libmpi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Hwloc_jll"),    # compat="2.0.0"
    Dependency("PMIx_jll"),     # compat="4.2.0"
    Dependency("Zlib_jll"),
    Dependency("libevent_jll"), # compat="2.0.21"
    Dependency("prrte_jll"),    # compat="3.0.0"
    Dependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"); compat="0.1", top_level=true),
]

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

init_block = raw"""
ENV["OPAL_PREFIX"] = artifact_dir
"""

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, init_block, julia_compat="1.6", preferred_gcc_version=v"5")
