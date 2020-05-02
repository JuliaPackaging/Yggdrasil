# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Leptonica"
version = v"1.79.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/DanBloomberg/leptonica.git", "002843bdf81ef4018fdf0f5c53262bbeab2b0fdc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_PROG=1 ../leptonica/
make -j${nprocs}
make -j${nprocs} xtractprotos
make install
mkdir -p $prefix/share/licenses/Leptonica
cp ../leptonica/leptonica-license.txt $prefix/share/licenses/Leptonica/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64)
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("converttops", :converttops),
    ExecutableProduct("convertsegfilestopdf", :convertsegfilestopdf),
    ExecutableProduct("xtractprotos", :xtractprotos),
    LibraryProduct("libleptonica", :liblept),
    ExecutableProduct("convertfilestops", :convertfilestops),
    ExecutableProduct("convertformat", :convertformat),
    ExecutableProduct("convertsegfilestops", :convertsegfilestops),
    ExecutableProduct("fileinfo", :fileinfo),
    ExecutableProduct("converttopdf", :converttopdf),
    ExecutableProduct("convertfilestopdf", :convertfilestopdf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Giflib_jll", uuid="59f7168a-df46-5410-90c8-f2779963d0ec"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
    Dependency(PackageSpec(name="libwebp_jll", uuid="c5f90fcd-3b7e-5836-afba-fc50a0988cb2"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
