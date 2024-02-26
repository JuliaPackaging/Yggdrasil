# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "avr_binutils"
version_string = "2.40"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-$(version_string).tar.xz", "0f8a4c272d7f17f369ded10a4aca28b8e304828e95526da482b0ccc4dfc9d8e1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/binutils-*
# for building as
apk add --upgrade texinfo
./configure --prefix=${prefix} \
    --target=avr \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-gas \
    --disable-dependency-tracking \
    --disable-werror \
    --disable-gprof \
    --disable-gprofng \
    --disable-gold \
    --disable-ar \
    --disable-avr-ar \
    --disable-libbfd \
    --disable-avr-libbfd \
    --disable-libctf \
    --disable-avr-libctf \
    --disable-size \
    --disable-nls \
    --enable-shared
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)


# The products that we will ensure are always built
products = [
    ExecutableProduct("as", :as, "avr/bin"),
    ExecutableProduct("objcopy", :objcopy, "avr/bin"),
    ExecutableProduct("readelf", :readelf, "avr/bin"),
    ExecutableProduct("objdump", :objdump, "avr/bin"),
    ExecutableProduct("strip", :binutils_strip, "avr/bin"),
    ExecutableProduct("nm", :nm, "avr/bin"),
    ExecutableProduct("ld", :ld, "avr/bin"),
    ExecutableProduct("avr-as", :avr_as),
    ExecutableProduct("avr-nm", :avr_nm),
    ExecutableProduct("avr-readelf", :avr_readelf),
    ExecutableProduct("avr-objcopy", :avr_objcopy),
    ExecutableProduct("avr-strip", :avr_strip),
    ExecutableProduct("avr-ld", :avr_ld),
    ExecutableProduct("avr-elfedit", :avr_elfedit),
    ExecutableProduct("avr-objdump", :avr_objdump)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
