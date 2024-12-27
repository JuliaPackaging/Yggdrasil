# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "x264"
# Find the major version number in the macro `X264_POINTVER` set in `version.sh`:
# https://code.videolan.org/videolan/x264/-/blob/master/version.sh?ref_type=heads
major_version = 0
# Find the value of `X264_BUILD` in the header file `x264.h`:
# https://code.videolan.org/videolan/x264/-/blob/master/x264.h?ref_type=heads#L48
x264_build = 164
# Upstream doesn't have proper releases, so we need to make up version numbers a
# bit. Versioning scheme is convoluted, follow me: we add and offset of "10_000" to the
# major version (inflated by 1000) because we need a major version larger than the previous
# calendar-based versioning, then we add also the `x264_build`, to make any new ABI-breaking
# version automatically semver-breaking.
version = VersionNumber(10_000 + 1000 * major_version + x264_build,
                        0,
                        0)

# Collection of sources required to build x264
sources = [
    GitSource("https://code.videolan.org/videolan/x264.git",
              "31e19f92f00c7003fa115047ce50978bc98c3a0d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/x264*
if [[ "${target}" == x86_64* ]] || [[ "${target}" == i686* ]]; then
    export AS=nasm
else
    export AS="${CC}"
fi
# Remove `-march` flag from `configure` script
sed -i 's/ -march=i686//g' configure
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared --enable-pic --disable-static
# Remove unsafe compilation flag
sed -i 's/ -ffast-math//g' config.mak
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("x264", :x264),
    LibraryProduct("libx264", :libx264),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("NASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6", clang_use_lld=false)
