# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROOT"
version = v"6.00.00"
version_slug = "6.30.00"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://root.cern.ch/download/root_v$(version_slug).source.tar.gz",
    "0592c066954cfed42312957c9cb251654456064fe2d8dabdcb8826f1c0099d71")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir build
cd build/
cmake -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -Dclad=OFF -Dpyroot=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_BUILD_TYPE=Release ../root-*
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    # Platform("aarch64", "linux"; libc = "glibc"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    # Platform("powerpc64le", "linux"; libc = "glibc"),
    # Platform("i686", "linux"; libc = "musl"),
    # Platform("x86_64", "linux"; libc = "musl"),
    # Platform("aarch64", "linux"; libc = "musl"),
    # Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    # Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Xorg_libX11_jll")
    BuildDependency("Xorg_xorgproto_jll")
    Dependency("Xorg_libXpm_jll")
    Dependency("VDT_jll")
    Dependency("Xorg_libXft_jll")
    Dependency("XRootD_jll")
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency("Lz4_jll")
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="Giflib_jll", uuid="59f7168a-df46-5410-90c8-f2779963d0ec"))
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4"))
    Dependency(PackageSpec(name="PCRE_jll", uuid="2f80f16e-611a-54ab-bc61-aa92de5b98fc"))
    Dependency(PackageSpec(name="Graphviz_jll", uuid="3c863552-8265-54e4-a6dc-903eb78fde85"))
    Dependency(PackageSpec(name="xxHash_jll", uuid="5fdcd639-92d1-5a06-bf6b-28f2061df1a9"))
    Dependency(PackageSpec(name="Librsvg_jll", uuid="925c91fb-5dd6-59dd-8e8c-345e74382d89"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
