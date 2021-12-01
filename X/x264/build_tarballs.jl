# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "x264"
version = v"2021.05.05"

# Collection of sources required to build x264
sources = [
    ArchiveSource("https://code.videolan.org/videolan/x264/-/archive/b684ebe04a6f80f8207a57940a1fa00e25274f81/x264-b684ebe04a6f80f8207a57940a1fa00e25274f81.tar.gz",
                  "7e37c8be8c12b1c6a9822ca4c888543042aca8bfe40715a69881f4756bdfa8f3"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/x264-*
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
platforms = supported_platforms(; experimental=true)

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
