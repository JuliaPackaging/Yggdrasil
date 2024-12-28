# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "eccodes"
version = v"2.36.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://confluence.ecmwf.int/download/attachments/45757960/eccodes-$version-Source.tar.gz",
                  "da74143a64b2beea25ea27c63875bc8ec294e69e5bd0887802040eb04151d79a"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.0-11.1/MacOSX11.1.sdk.tar.xz",
                  "9b86eab03176c56bb526de30daa50fa819937c54b280364784ce431885341bf6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eccodes-*-Source
if [[ ${target} = *-mingw* ]] ; then
    chmod +x cmake/ecbuild_windows_replace_symlinks.sh
    atomic_patch -p1 /workspace/srcdir/patches/windows.patch
fi
atomic_patch -p1 /workspace/srcdir/patches/unix.patch
atomic_patch -p1 /workspace/srcdir/patches/kinds.patch
mkdir build
cd build
export CFLAGS="-I${includedir}"
if [[ ${target} = *apple-darwin* ]] ; then
    # This is needed for std::bad_optional_access
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX11.1.sdk
    sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    maccmakeargs="-DCMAKE_SYSROOT=$apple_sdk_root -DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks -DCMAKE_OSX_DEPLOYMENT_TARGET=10.14"
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_EXAMPLES=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_NETCDF=OFF \
    -DENABLE_PNG=ON \
    -DENABLE_FORTRAN=ON \
    -DENABLE_ECCODES_THREADS=ON \
    -DENABLE_AEC=ON $maccmakeargs \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# 32 bit platforms are not supported by eccodes
filter!(p -> nbits(p) == 64, platforms)
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)
filter!(p -> libgfortran_version(p) != v"3", platforms) # Avoid too old GCC
# The products that we will ensure are always built
products = [
    LibraryProduct("libeccodes", :eccodes),
    LibraryProduct("libeccodes_f90", :libeccodes_f90),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("libpng_jll"; compat="~1.6.43"),
    Dependency("OpenJpeg_jll", compat="~2.5.2"),
    Dependency("libaec_jll", compat="~1.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well. GCC 8 because we need C++17
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8", clang_use_lld=false, julia_compat="1.6")
