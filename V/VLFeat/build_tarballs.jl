# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "VLFeat"
version = v"0.9.21"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/vlfeat/vlfeat.git", "2f6abbf13fe7ee052bc970480efaca9d6b0c195d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd vlfeat

atomic_patch -p1 ../patches/vlfeat-march.patch
atomic_patch -p1 ../patches/vlfeat-glibc-limitation.patch
atomic_patch -p1 ../patches/vlfeat-mingw-lowercase-windows-include.patch
atomic_patch -p1 ../patches/vlfeat-windows.patch

make_args=()

if [[ $target != x86_64-* ]]; then
    make_args+="DISABLE_AVX=1 "
    make_args+="DISABLE_SSE2=1 "
fi

if [[ $target == *-apple-darwin* ]]; then
    ARCH=maci64
elif [[ $target == i686-w64-mingw32 ]]; then
    ARCH=win32
elif [[ $target == x86_64-w64-mingw32 ]]; then
    ARCH=win64
elif [[ $nbits == 32 ]]; then
    ARCH=glnx86
else
    ARCH=glnxa64
fi
make_args+="ARCH=$ARCH "

if [[ $target == *-apple-* ]]; then
    make_args+="SDKROOT=/opt/$target/$target/sys-root "
fi

make ${make_args[@]} dll

install -vD bin/$ARCH/libvl.$dlext $libdir/libvl.$dlext
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libvl", :libvl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
