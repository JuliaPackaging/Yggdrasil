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

if [[ "${target}" == *-*-musl ]]; then
    # Patch to fix messy header situation on musl
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_syscall.patch"
fi

# Patch to disable tests
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_disable_tests.patch"

# Patch to properly link to rt
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_link_rt.patch"

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
make -j${nproc} || true
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("qemu-system-xtensaeb"    , :qemu_system_xtensaeb    ),
    ExecutableProduct("qemu-system-xtensa"      , :qemu_system_xtensa      ),
    ExecutableProduct("qemu-system-tricore"     , :qemu_system_tricore     ),
    ExecutableProduct("qemu-system-sparc64"     , :qemu_system_sparc64     ),
    ExecutableProduct("qemu-system-sparc"       , :qemu_system_sparc       ),
    ExecutableProduct("qemu-system-x86_64"      , :qemu_system_x86_64      ),
    ExecutableProduct("qemu-system-sh4eb"       , :qemu_system_sh4eb       ),
    ExecutableProduct("qemu-system-s390x"       , :qemu_system_s390x       ),
    ExecutableProduct("qemu-system-sh4"         , :qemu_system_sh4         ),
    ExecutableProduct("qemu-system-rx"          , :qemu_system_rx          ),
    ExecutableProduct("qemu-system-riscv32"     , :qemu_system_riscv32     ),
    ExecutableProduct("qemu-system-riscv64"     , :qemu_system_riscv64     ),
    ExecutableProduct("qemu-system-ppc64"       , :qemu_system_ppc64       ),
    ExecutableProduct("qemu-system-ppc"         , :qemu_system_ppc         ),
    ExecutableProduct("qemu-system-or1k"        , :qemu_system_or1k        ),
    ExecutableProduct("qemu-system-nios2"       , :qemu_system_nios2       ),
    ExecutableProduct("qemu-system-microblazeel", :qemu_system_microblazeel),
    ExecutableProduct("qemu-system-microblaze"  , :qemu_system_microblaze  ),
    ExecutableProduct("qemu-system-m68k"        , :qemu_system_m68k        ),
    ExecutableProduct("qemu-system-i386"        , :qemu_system_i386        ),
    ExecutableProduct("qemu-system-cris"        , :qemu_system_cris        ),
    ExecutableProduct("qemu-system-hppa"        , :qemu_system_hppa        ),
    ExecutableProduct("qemu-system-avr"         , :qemu_system_avr         ),
    ExecutableProduct("qemu-system-arm"         , :qemu_system_arm         ),
    ExecutableProduct("qemu-system-alpha"       , :qemu_system_alpha       ),
    ExecutableProduct("qemu-system-aarch64"     , :qemu_system_aarch64     ),
    ExecutableProduct("qemu-system-mips"        , :qemu_system_mips        ),
    ExecutableProduct("qemu-system-mipsel"      , :qemu_system_mipsel      ),
    ExecutableProduct("qemu-system-mips64el"    , :qemu_system_mips64el    ),
    ExecutableProduct("qemu-system-mips64"      , :qemu_system_mips64      ),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Pixman_jll"),
    Dependency("Glib_jll"; compat="2.68.1"),
    Dependency("PCRE_jll"),
    BuildDependency("Gettext_jll"),
    Dependency("libcap_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
