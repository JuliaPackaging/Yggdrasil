using BinaryBuilder, Pkg.BinaryPlatforms

name = "Qemu"
version = v"4.1.0"

# Collection of sources required to build libffi
sources = [
    "https://gitlab.com/virtio-fs/qemu.git" =>
    "bf5775237ee563b4baa1c7f3c1a65b7c93b93fca",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qemu

# Patch out usage of MADV_NOHUGEPAGE which does not exist in glibc 2.12.X
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_madv_nohugepage.patch"

# Patch in adapter for `clock_gettime()` on macOS 10.12-
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_clock_gettime.patch"

# Patch to fix pointer mismatch between `size_t` and `uint64_t`
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_size_uint64.patch"

# Configure, ignoring some warnings that we don't need, etc...
./configure --host-cc="${HOSTCC}" --extra-cflags="-I${prefix}/include -Wno-unused-result" --disable-cocoa --prefix=$prefix

echo '#!/bin/true ' > /usr/bin/Rez
echo '#!/bin/true ' > /usr/bin/SetFile
chmod +x /usr/bin/Rez
chmod +x /usr/bin/SetFile
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64; libc=:glibc),
    MacOS(),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("qemu-system-x86_64", :qemu_system_x86_64),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Pixman_jll",
    "Glib_jll",
    "PCRE_jll",
    "Gettext_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
