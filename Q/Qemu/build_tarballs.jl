using BinaryBuilder

name = "Qemu"
version = v"6.2.0"

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://download.qemu.org/qemu-6.2.0.tar.xz",
                  "68e15d8e45ac56326e0b9a4afa8b49a3dfe8aba3488221d098c84698bca65b45"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qemu-*

# Patch out usage of MADV_NOHUGEPAGE which does not exist in glibc 2.12.X
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_madv_nohugepage.patch"

# Patch to include `falloc` header in `strace.c`
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_falloc.patch"

# Patch to not fail if trying to clean up non-existent files
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_no_fail_in_cleanup.patch"

if [[ "${target}" == *-*-musl ]]
    # Patch to fix messy header situation on musl
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_syscall.patch"
fi

## Patch in adapter for `clock_gettime()` on macOS 10.12-
#atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_clock_gettime.patch"
#
## Patch to fix pointer mismatch between `size_t` and `uint64_t`
#atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_size_uint64.patch"

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
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("i686", "linux"; libc="musl"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("qemu-system-x86_64", :qemu_system_x86_64),
    ExecutableProduct("qemu-system-aarch64", :qemu_system_aarch64),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Pixman_jll"),
    Dependency("Glib_jll", v"2.59.0"; compat="2.59.0"),
    Dependency("PCRE_jll"),
    # TOOD: verify Gettext is actually needed at runtime
    Dependency("Gettext_jll"),
    Dependency("libcap_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
