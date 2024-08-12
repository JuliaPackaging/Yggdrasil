# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "arm_binutils"
version_string = "2.41"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/binutils/binutils-$(version_string).tar.xz", "ae9a5789e23459e59606e6714723f2d3ffc31c03174191ef0d015bdf06007450")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/binutils-*
# for building as
apk update
apk add --upgrade texinfo
./configure --prefix=${prefix} \
    --target=arm-none-eabi \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-gas \
    --disable-dependency-tracking \
    --disable-werror \
    --disable-gprof \
    --disable-gprofng \
    --disable-gold \
    --disable-ar \
    --disable-arm-none-eabi-ar \
    --disable-libbfd \
    --disable-arm-none-eabi-libbfd \
    --disable-libctf \
    --disable-arm-none-eabi-libctf \
    --disable-size \
    --disable-arm-none-eabi-size \
    --disable-nls \
    --disable-arm-none-eabi-nls \
    --enable-shared
make -j${nprocs}
make install
rm **/config.cache
./configure --prefix=${prefix} \
    --target=arm-none-eabihf \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-gas \
    --disable-dependency-tracking \
    --disable-werror \
    --disable-gprof \
    --disable-gprofng \
    --disable-gold \
    --disable-arm \
    --disable-arm-none-eabihf-ar \
    --disable-libbfd \
    --disable-arm-none-eabihf-libbfd \
    --disable-libctf \
    --disable-arm-none-eabihf-libctf \
    --disable-size \
    --disable-arm-none-eabihf-size \
    --disable-nls \
    --disable-arm-none-eabihf-nls \
    --enable-shared
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)


# The products that we will ensure are always built
products = [
    ExecutableProduct("arm-none-eabi-as", :arm_none_eabi_as),
    ExecutableProduct("arm-none-eabi-objcopy", :arm_none_eabi_objcopy),
    ExecutableProduct("arm-none-eabi-readelf", :arm_none_eabi_readelf),
    ExecutableProduct("arm-none-eabi-objdump", :arm_none_eabi_objdump),
    ExecutableProduct("arm-none-eabi-strip", :arm_none_eabi_strip),
    ExecutableProduct("arm-none-eabi-nm", :arm_none_eabi_nm),
    ExecutableProduct("arm-none-eabi-ld", :arm_none_eabi_ld),
    ExecutableProduct("arm-none-eabihf-as", :arm_none_eabihf_as),
    ExecutableProduct("arm-none-eabihf-objcopy", :arm_none_eabihf_objcopy),
    ExecutableProduct("arm-none-eabihf-readelf", :arm_none_eabihf_readelf),
    ExecutableProduct("arm-none-eabihf-objdump", :arm_none_eabihf_objdump),
    ExecutableProduct("arm-none-eabihf-strip", :arm_none_eabihf_strip),
    ExecutableProduct("arm-none-eabihf-nm", :arm_none_eabihf_nm),
    ExecutableProduct("arm-none-eabihf-ld", :arm_none_eabihf_ld),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
