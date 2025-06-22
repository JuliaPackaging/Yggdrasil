# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CFITSIO"
version = v"4.6.2"

# Collection of sources required to build CFITSIO
sources = [
    ArchiveSource("http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-$(version).tar.gz",
                  "66fd078cc0bea896b0d44b120d46d6805421a5361d3a5ad84d9f397b1b5de2cb"),
    # DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cfitsio*

if [[ "${target}" == *-mingw* ]]; then
    # This is ridiculous: when CURL is enabled, CFITSIO defines a macro,
    # `TBYTE`, that has the same name as a mingw macro.  Let's rename all
    # `TBYTE` to `_TBYTE`.
    sed -i 's/\<TBYTE\>/_TBYTE/g' $(grep -lr '\<TBYTE\>')
fi

options=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_FIND_ROOT_PATH=${prefix}
    -DCMAKE_SYSTEM_LIBRARY_PATH=/opt/${target}/${target}/sys-root/usr/lib64/lp64d
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DBUILD_SHARED_LIBS=ON
    -DTESTS=OFF
    -DUSE_BZIP2=ON
    -DUSE_PTHREADS=ON
    -DCMAKE_C_FLAGS=-DgFortran
)

if [[ ${target} == x86_64-* ]]; then
    options+=(
        -DUSE_SSE2=ON
        -DUSE_SSSE3=ON
    )
fi

cmake -B builddir "${options[@]}"
cmake --build builddir -j ${nproc}
cmake --install builddir
install_license licenses/License.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcfitsio", :libcfitsio),
    ExecutableProduct("fpack", :fpack),
    ExecutableProduct("funpack", :funpack),
    ExecutableProduct("fitscopy", :fitscopy),
    ExecutableProduct("fitsverify", :fitsverify),
    ExecutableProduct("imcopy", :imcopy),
    # Not available on Windows
    # ExecutableProduct("smem", :smem),
    # ExecutableProduct("speed", :speed),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# When using lld for AArch64 macOS, linking fails with
#     ld64.lld: error: -dylib_current_version 10.4.3.1: malformed version
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")
