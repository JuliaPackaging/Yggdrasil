# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "P4est"
version = v"2.8.1"
p4est_version = v"2.8"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://p4est.github.io/release/p4est-2.8.tar.gz",
                  "6a0586e3abac06c20e31b1018f3a82a564a6a0d9ff6b7f6c772a9e6b0f0cc5e4"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd p4est-*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mpi-constants.patch"

if [[ "${target}" == *-freebsd* ]]; then
  export LIBS="-lm"
elif [[ "${target}" == x86_64-linux-musl ]]; then
  # We can't run Fortran programs for the native platform, so a check that the
  # Fortran compiler works would fail.  Small hack: swear that we're
  # cross-compiling.  See:
  # https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/50.
  sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
  sed -i 's/cross_compiling=no/cross_compiling=yes/' sc/configure
fi

# Set default preprocessor and linker flags
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

# Special Windows treatment
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
  # Set linker flags only at build time (see https://docs.binarybuilder.org/v0.3/troubleshooting/#Windows)
  FLAGS+=(LDFLAGS="$LDFLAGS -no-undefined")
  # Configure does not find the correct Fortran compiler
  export F77="f77"
  # Link against ws2_32 to use the htonl function from winsock2.h
  export LIBS="-lmsmpi -lws2_32"
  # Disable MPI I/O on Windows since it causes p4est to crash
  mpiopts="--enable-mpi --disable-mpiio"
  # Linker looks for libmsmpi instead of msmpi, copy existing symlink
  cp -d ${libdir}/msmpi.dll ${libdir}/libmsmpi.dll
else
  # Use MPI including MPI I/O on all other platforms
  export CC="mpicc"
  export CXX="mpic++"
  mpiopts="--enable-mpi"
fi

# Configure, build, install
# Note: BLAS is disabled since it is only needed for SC if it is used outside of p4est
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --without-blas ${mpiopts}
make -j${nproc} "${FLAGS[@]}"
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# p4est with MPI enabled does not compile for 32 bit Windows
platforms = filter(p -> !(Sys.iswindows(p) && nbits(p) == 32), platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1")

# Disable OpenMPI since the build is broken. This could probably be fixed
# via more explicit MPI configuration options.
platforms = filter(p -> p["mpi"] ≠ "openmpi", platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libp4est", :libp4est),
    LibraryProduct("libsc", :libsc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"8.1.0")
