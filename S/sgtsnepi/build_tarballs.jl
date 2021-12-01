# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sgtsnepi"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fcdimitr/sgtsnepi.git", "40c6acfb736b02e7f1457a936ce16ab85964806b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd sgtsnepi/
apk add meson --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
meson --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson build
cd build/
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libsgtsnepi", :libsgtsnepi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="cilkrts_jll", uuid="71772805-00bc-5a29-9044-a26d819b7806"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
