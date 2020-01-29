# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sdsl-lite"
version = v"2.1.1"

# Collection of sources required to complete build
sources = [
    "https://github.com/simongog/sdsl-lite.git" =>
    "0546faf0552142f06ff4b201b671a5769dd007ad",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sdsl-lite/
sed -ri \
	-e "s/^cmake /cmake -DCMAKE_TOOLCHAIN_FILE=\\$\\{CMAKE_TARGET_TOOLCHAIN\\} -DBUILD_SHARED_LIBS=ON /" \
	-e "s/^make sdsl/make -j\\$nprocs sdsl/" \
	install.sh 
./install.sh $prefix
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
    FreeBSD(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libsdsl", :libsdsl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
