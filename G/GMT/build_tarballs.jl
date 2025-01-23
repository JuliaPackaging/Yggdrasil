# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GMT"
version = v"6.5.3"
GSHHG_VERSION="2.3.7"
DCW_VERSION="2.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/GenericMappingTools/gmt", 
    "504e6d226ba1da344137d610a5256042b7cd2638"),
    
    ArchiveSource("https://github.com/GenericMappingTools/gshhg-gmt/releases/download/$GSHHG_VERSION/gshhg-gmt-$GSHHG_VERSION.tar.gz",
        "9bb1a956fca0718c083bef842e625797535a00ce81f175df08b042c2a92cfe7f"),

    ArchiveSource("https://github.com/GenericMappingTools/DCW-type-files/releases/download/new/dcw-gmt-$(DCW_VERSION)_plus.tar.gz",
        "096E64535A7E3CC1F870A9D6A569B5BAC63040B602D04F4077D41B62EC0F7BBB")
]

#     ArchiveSource("https://github.com/GenericMappingTools/dcw-gmt/releases/download/$DCW_VERSION/dcw-gmt-$DCW_VERSION.tar.gz",

# Bash recipe for building across all platforms
script = """
GSSHG_VERSION="$(GSHHG_VERSION)"
GSSHG="gshhg-gmt-$(GSHHG_VERSION)"
DCW="dcw-gmt-$(DCW_VERSION)"
""" * raw"""
cd ${WORKSPACE}/srcdir/gmt
mkdir build
cd build/

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHAVE_QSORT_R_GLIBC=False \
    -DBUILD_IMGTEXTURE=TRUE \
    -DHAVE___BUILTIN_BSWAP16=False \
    -DHAVE___BUILTIN_BSWAP32=False \
    -DHAVE___BUILTIN_BSWAP64=False \
    -DGMT_ENABLE_OPENMP=True \
    -DJULIA_GHOST_JLL=True \
    -DGSHHG_PATH=${WORKSPACE}/srcdir/${GSSHG} \
    -DGSHHG_VERSION=${GSHHG_VERSION_numeric} \
    -DDCW_PATH=${WORKSPACE}/srcdir/${DCW} \
    .. 
make -j${nproc} 
make install 

# copy license
install_license ../LICENSE.TXT
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
    LibraryProduct(["libpostscriptlight", "postscriptlight"], :libpostscriptlight),
    LibraryProduct(["libgmt", "gmt"], :libgmt),
    ExecutableProduct("gmt", :gmt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"); compat="7.73.0, 8.0.1")
    Dependency("NetCDF_jll", compat="400.902.210")
    Dependency("PROJ_jll", compat="902")
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"); compat="302.1000")
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="PCRE_jll", uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc"))
    Dependency(PackageSpec(name="LAPACK32_jll", uuid="17f450c3-bd24-55df-bb84-8c51b4b939e3"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"))
    Dependency(PackageSpec(name="Ghostscript_jll", uuid="61579ee1-b43e-5ca0-a5da-69d92c66a64b"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms))
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
