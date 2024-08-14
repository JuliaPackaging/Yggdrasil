using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "VMEC"
upstream_version = v"1.3.0"
version_patch_offset = 0
version = VersionNumber(upstream_version.major,
                        upstream_version.minor,
                        upstream_version.patch * 100 + version_patch_offset)

sources = [
    ArchiveSource("https://gitlab.com/wistell/VMEC2000/-/archive/v$(upstream_version).tar",
                  "4c13c0312a6b4061357be35122ac507b0a25c2d5cd0dd03dd1b9e31818318528"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/VMEC*
# From the SCALAPACK build_tarballs with MPItrampoline
# We need to specify the MPI libraries explicitly because the
# CMakeLists.txt doesn't properly add them when linking
MPILIBS=()
if grep -q MSMPI_VER "${prefix}/include/mpi.h"; then
    MPILIBS=(-lmsmpifec64 -lmsmpi64)
elif grep -q MPICH "${prefix}/include/mpi.h"; then
    MPILIBS=(-lmpifort -lmpi)
elif grep -q MPItrampoline "${prefix}/include/mpi.h"; then
    MPILIBS=(-lmpitrampoline)
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpi_inc.patch
    MPIF_PATH=$(find ${libdir} -name 'mpif.h')
    MPIF_PATH=$(sed "s:\/:\\\/:g" <<< "$MPIF_PATH")
    sed "s/INCLUDE \'mpif.h\'/INCLUDE \'${MPIF_PATH}\'/" Sources/LIBSTELL_minimal/mpi_inc.f | cat > Sources/LIBSTELL_minimal/mpi_inc.patched
    mv Sources/LIBSTELL_minimal/mpi_inc.patched Sources/LIBSTELL_minimal/mpi_inc.f
elif grep -q OMPI_MAJOR_VERSION "$prefix/include/mpi.h"; then
    MPILIBS=(-lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi)
fi
F_FLAGS=(-O3)
# Add `-fallow-argument-mismatch` if supported
: >empty.f
if gfortran -c -fallow-argument-mismatch empty.f >/dev/null 2>&1; then
    F_FLAGS+=(-fallow-argument-mismatch)
fi
rm -f empty.*

if [[ ${target} == *mingw* ]]; then
     sed "s/LT_INIT/LT_INIT(win32-dll)/" configure.ac | cat > configure.ac.2
     mv configure.ac.2 configure.ac
     ./autogen.sh
     ./configure CC=gcc FC=gfortran F77=gfortran --build=${MACHTYPE} --with-mkl --host=${target} --target=${target} --prefix=${prefix}
     # Deal with the issue that gcc doesn't accept -no-undefined at configure step
     sed "s/AM_LDFLAGS =/AM_LDFLAGS =-no-undefined/" Makefile | cat > Makefile.2
     mv Makefile.2 Makefile
     make && make install && make clean

     ./configure CC=gcc FC=gfortran F77=gfortran --build=${MACHTYPE} --host=${target} --target=${target} --prefix=${prefix}
     # Deal with the issue that gcc doesn't accept -no-undefined at configure step
     sed "s/AM_LDFLAGS =/AM_LDFLAGS =-no-undefined/" Makefile | cat > Makefile.2
     mv Makefile.2 Makefile
     make && make install && make clean

else
    ./autogen.sh
    ./configure CC=mpicc FC=mpifort F77=mpifort FFLAGS="${F_FLAGS[*]}" FCFLAGS="${F_FLAGS}" LIBS="${MPILIBS[*]}" --with-mkl --build=${MACHTYPE} --host=${target} --target=${target} --prefix=${prefix}
    make && make install && make clean

    ./configure CC=mpicc FC=mpifort F77=mpifort FFLAGS="${F_FLAGS[*]}" FCFLAGS="${F_FLAGS[*]}" LIBS="${MPILIBS[*]}" --build=${MACHTYPE} --host=${target} --target=${target} --prefix=${prefix}
    make && make install && make clean
fi
"""

# This is for MPItrampoline implementation
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    function augment_platform!(platform::Platform)
        augment_mpi!(platform)
    end
"""

platforms = expand_gfortran_versions(supported_platforms())

# Filter out libgfortran_version = 3.0.0 which is incompatible with VMEC
filter!(p ->libgfortran_version(p) >= v"4", platforms)

# Filter incompatible architectures and operating systems
filter!(p -> arch(p) == "x86_64", platforms)
filter!(!Sys.isfreebsd, platforms)

# Right now VMEC only works with libc=glibc, filter out any musl dependencies
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
# Don't automatically dl_open so that the appropriate 
# library can be loaded on intiation of VMEC.jl
products = [
    LibraryProduct("libvmec_mkl", :libvmec_mkl, dont_dlopen=true),
    LibraryProduct("libvmec_openblas", :libvmec_openblas, dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SCALAPACK_jll"),
    Dependency("OpenBLAS_jll"),
    Dependency("MKL_jll"), 
    Dependency("CompilerSupportLibraries_jll")
]

# Needed from MPItrampoline
all_platforms, platform_dependencies = MPI.augment_platforms(platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, all_platforms, products, dependencies; julia_compat = "1.6", augment_platform_block)
