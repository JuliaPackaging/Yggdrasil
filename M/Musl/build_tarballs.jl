using BinaryBuilder

name = "Musl"
version = v"1.1.19"

# sources to build, such as mingw32, our patches, etc....
sources = [
    "https://www.musl-libc.org/releases/musl-1.1.19.tar.gz" =>
    "db59a8578226b98373f5b27e61f0dd29ad2456f4aa9cec587ba8c24508e4c1d9",
    "../KernelHeaders/products/",
]

# Bash recipe for building across all platforms
script = raw"""
mkdir ${WORKSPACE}/srcdir/musl_build
cd ${WORKSPACE}/srcdir/musl_build

# Extract mounted-in KernelHeaders
tar -C ${prefix} -zxf ${WORKSPACE}/srcdir/KernelHeaders.*.${target}.tar.gz

# The sysroot comes from the tarball we just extracted above
sysroot=${prefix}/${target}/sys-root

${WORKSPACE}/srcdir/musl-*/configure --prefix=/usr \
    --host=${target} \
    --with-headers="${sysroot}/usr/include" \
    --with-binutils=/opt/${target}/bin \
    --disable-multilib \
    --disable-werror \
    CROSS_COMPILE="${target}-"

make -j${nproc}
make install DESTDIR=${sysroot}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, :musl)
    Linux(:i686, :musl)
    Linux(:aarch64, :musl)
    Linux(:armv7l, :musl, :eabihf)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libc", :libc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
