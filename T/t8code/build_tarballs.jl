# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "t8code"
version = v"1.6.1"

tarball = "https://github.com/DLR-AMR/t8code/releases/download/v$(version)/t8-$(version).tar.gz"
sha256sum = "dc96effa7c1ad1d50437fefdd0963f6ef7c943eb10a372a4e8546a5f2970a412"

# Collection of sources required to complete build
sources = [ArchiveSource(tarball, sha256sum), DirectorySource("./bundled")]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/t8*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mpi-constants.patch"

# Set default preprocessor and linker flags
# Note: This is *crucial* for Windows builds as otherwise the wrong libraries are picked up!
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export CFLAGS="-O3"
export CXXFLAGS="-O3"

# Set necessary flags for FreeBSD
if [[ "${target}" == *-freebsd* ]]; then
  export LIBS="${LIBS} -lm"
fi

# Set necessary flags for Windows and non-Windodws systems
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
  # Pass -lmsmpi explicitly to linker as the absolute library path specified in LIBS below is not always propagated properly
  export LDFLAGS="$LDFLAGS -Wl,-lmsmpi"
  # Set linker flags only at build time (see https://docs.binarybuilder.org/v0.3/troubleshooting/#Windows)
  FLAGS+=(LDFLAGS="$LDFLAGS -no-undefined")
  # Link against ws2_32 to use the htonl function from winsock2.h
  export LIBS="${LIBS} ${libdir}/msmpi.dll -lws2_32"
  # Disable MPI I/O on Windows since it causes p4est to crash
  mpiopts="--enable-mpi --disable-mpiio"
else
  # Use MPI including MPI I/O on all other platforms
  export CC="mpicc"
  export CXX="mpicxx"
  mpiopts="--enable-mpi"
fi

# Temporary fix according to: https://github.com/JuliaPackaging/Yggdrasil/issues/7745
if [[ "${target}" == *-apple-* ]]; then
  export LDFLAGS="$LDFLAGS -fuse-ld=ld"
fi

# Run configure
./configure \
  --prefix="${prefix}" \
  --build=${MACHTYPE} \
  --host=${target} \
  --disable-static \
  --without-blas \
  ${mpiopts}

# Build & install
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

# Disable OpenMPI since it doesn't build. This could probably be fixed
# via more explicit MPI configuraiton options.
platforms = filter(p -> p["mpi"] ≠ "openmpi", platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsc"], :libsc),
    LibraryProduct(["libp4est"], :libp4est),
    LibraryProduct(["libt8"], :libt8),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"12.1.0")
