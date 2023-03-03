# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GMT"
version = v"6.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/GenericMappingTools/gmt", 
    "d6951f02c0922d53741da0d5d3ed7659c285b350")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
#if [[ "${target}" == *-mingw* ]]; then
#    for f in ${WORKSPACE}/srcdir/patches/*.patch; do
#        atomic_patch -p1 ${f}
#    done
#fi
cd gmt
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHAVE_QSORT_R_GLIBC=False \
    -DHAVE___BUILTIN_BSWAP16=False \
    -DHAVE___BUILTIN_BSWAP32=False \
    -DHAVE___BUILTIN_BSWAP64=False \
    .. 
make -j${nproc} 
make install 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "windows"; ),
    Platform("i686", "windows"; ),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libpostscriptlight", :libpostscriptlight),
    LibraryProduct("libgmt", :libgmt),
    ExecutableProduct("gmt", :gmt)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"); compat="7.73.0")
    Dependency("NetCDF_jll", compat="400.702.402")
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="PCRE_jll", uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc"))
    Dependency(PackageSpec(name="LAPACK32_jll", uuid="17f450c3-bd24-55df-bb84-8c51b4b939e3"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="FFMPEG_jll", uuid="b22a6f82-2f65-5046-a5b2-351ab43fb4e5"))
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
