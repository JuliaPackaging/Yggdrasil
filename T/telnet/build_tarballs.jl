# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "telnet"
version = v"2.5.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/inetutils/inetutils-$(version.major).$(version.minor).tar.xz",
                  "87697d60a31e10b5cb86a9f0651e1ec7bee98320d048c0739431aac3d5764fb6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/inetutils-*
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-servers \
    --disable-clients \
    --enable-telnet
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)

# The products that we will ensure are always built
products = [
    ExecutableProduct("telnet", :telnet)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a"))
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"))
    Dependency(PackageSpec(name="libxcrypt_legacy_jll", uuid="5ef642bb-a58b-5208-ae37-583168b2c491"); platforms=filter(p -> libc(p) == "glibc", platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
