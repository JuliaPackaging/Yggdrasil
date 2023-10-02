using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "OpenMPI"
version = v"4.1.6"
sources = [
    ArchiveSource("https://download.open-mpi.org/release/open-mpi/v$(version.major).$(version.minor)/openmpi-$(version).tar.gz",
                  "44da277b8cdc234e71c62473305a09d63f4dcca292ca40335aab7c4bf0e6a566"),
    DirectorySource("./bundled"),
]

script = raw"""
################################################################################
# Install OpenMPI
################################################################################

# Enter the funzone
cd ${WORKSPACE}/srcdir/openmpi-*

atomic_patch -p1 ../patches/0001-ompi-mca-sharedfp-sm-Include-missing-sys-stat.h-in-s.patch

if [[ "${target}" == *-freebsd* ]]; then
    # Help compiler find `complib/cl_types.h`
    export CPPFLAGS="-I/opt/${target}/${target}/sys-root/include/infiniband"
fi

# We use `--enable-script-wrapper-compilers` to turn the compiler
# wrappers (`mpicc` etc.) into scripts instead of binaries. As scripts,
# they can be run in a cross-compiling environment, and cmake can
# infer the MPI options. Otherwise, the MPI options need to be
# specified manually for OpenMPI to work.

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared=yes \
    --enable-static=no \
    --without-cs-fs \
    --enable-mpi-fortran=usempif08 \
    --enable-script-wrapper-compilers \
    --with-cross=${WORKSPACE}/srcdir/${target}

# Build the library
make -j${nproc}

# Install the library
make install

################################################################################
# Install licenses
################################################################################

install_license $WORKSPACE/srcdir/openmpi*/LICENSE
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = filter(p -> !Sys.iswindows(p) && !(arch(p) == "armv6l" && libc(p) == "glibc"), supported_platforms())
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
    Dependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"); compat="0.1", top_level=true),
]

init_block = raw"""
ENV["OPAL_PREFIX"] = artifact_dir
"""

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, init_block, julia_compat="1.6", preferred_gcc_version=v"5")
