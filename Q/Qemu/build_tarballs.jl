using BinaryBuilder, BinaryBuilderBase, Pkg

name = "Qemu"
version = v"7.2.9"

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://download.qemu.org/qemu-$(version).tar.xz",
                  "73f6583d68cc5af36ebc95feabc9df53098ccdce4278084cce2938babf28ab4a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qemu-*
install_license COPYING

# include `falloc` header in `strace.c` (requires glibc 2.25)
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_falloc.patch"

if [[ "${target}" == *-*-musl ]]; then
    # fix messy header situation on musl
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_syscall.patch"

    # include kernel headers for a definition of speculation control prctls (musl 1.1.20)
    sed -i 's/#include <sys\/prctl.h>/#include <linux\/prctl.h>/g' linux-user/syscall.c
fi

# disable tests
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_disable_tests.patch"

# properly link to rt
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/qemu_link_rt.patch"

# Configure, ignoring some warnings that we don't need, etc...
./configure --prefix=$prefix --host-cc="${HOSTCC}" \
    --extra-cflags="-I${prefix}/include -Wno-unused-result" \
    --disable-cocoa

make -j${nproc}

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
    # system-mode emulation
    ExecutableProduct("qemu-system-aarch64"     , :qemu_system_aarch64     ),
    ExecutableProduct("qemu-system-alpha"       , :qemu_system_alpha       ),
    ExecutableProduct("qemu-system-arm"         , :qemu_system_arm         ),
    ExecutableProduct("qemu-system-avr"         , :qemu_system_avr         ),
    ExecutableProduct("qemu-system-cris"        , :qemu_system_cris        ),
    ExecutableProduct("qemu-system-hppa"        , :qemu_system_hppa        ),
    ExecutableProduct("qemu-system-i386"        , :qemu_system_i386        ),
    ExecutableProduct("qemu-system-m68k"        , :qemu_system_m68k        ),
    ExecutableProduct("qemu-system-microblaze"  , :qemu_system_microblaze  ),
    ExecutableProduct("qemu-system-microblazeel", :qemu_system_microblazeel),
    ExecutableProduct("qemu-system-mips"        , :qemu_system_mips        ),
    ExecutableProduct("qemu-system-mips64"      , :qemu_system_mips64      ),
    ExecutableProduct("qemu-system-mips64el"    , :qemu_system_mips64el    ),
    ExecutableProduct("qemu-system-mipsel"      , :qemu_system_mipsel      ),
    ExecutableProduct("qemu-system-nios2"       , :qemu_system_nios2       ),
    ExecutableProduct("qemu-system-or1k"        , :qemu_system_or1k        ),
    ExecutableProduct("qemu-system-ppc"         , :qemu_system_ppc         ),
    ExecutableProduct("qemu-system-ppc64"       , :qemu_system_ppc64       ),
    ExecutableProduct("qemu-system-riscv32"     , :qemu_system_riscv32     ),
    ExecutableProduct("qemu-system-riscv64"     , :qemu_system_riscv64     ),
    ExecutableProduct("qemu-system-rx"          , :qemu_system_rx          ),
    ExecutableProduct("qemu-system-s390x"       , :qemu_system_s390x       ),
    ExecutableProduct("qemu-system-sh4"         , :qemu_system_sh4         ),
    ExecutableProduct("qemu-system-sh4eb"       , :qemu_system_sh4eb       ),
    ExecutableProduct("qemu-system-sparc"       , :qemu_system_sparc       ),
    ExecutableProduct("qemu-system-sparc64"     , :qemu_system_sparc64     ),
    ExecutableProduct("qemu-system-tricore"     , :qemu_system_tricore     ),
    ExecutableProduct("qemu-system-x86_64"      , :qemu_system_x86_64      ),
    ExecutableProduct("qemu-system-xtensa"      , :qemu_system_xtensa      ),
    ExecutableProduct("qemu-system-xtensaeb"    , :qemu_system_xtensaeb    ),

    # user-mode emulation
    ExecutableProduct("qemu-aarch64"            , :qemu_aarch64            ),
    ExecutableProduct("qemu-aarch64_be"         , :qemu_aarch64_be         ),
    ExecutableProduct("qemu-alpha"              , :qemu_alpha              ),
    ExecutableProduct("qemu-arm"                , :qemu_arm                ),
    ExecutableProduct("qemu-armeb"              , :qemu_armeb              ),
    ExecutableProduct("qemu-cris"               , :qemu_cris               ),
    ExecutableProduct("qemu-edid"               , :qemu_edid               ),
    ExecutableProduct("qemu-ga"                 , :qemu_ga                 ),
    ExecutableProduct("qemu-hexagon"            , :qemu_hexagon            ),
    ExecutableProduct("qemu-hppa"               , :qemu_hppa               ),
    ExecutableProduct("qemu-i386"               , :qemu_i386               ),
    ExecutableProduct("qemu-img"                , :qemu_img                ),
    ExecutableProduct("qemu-io"                 , :qemu_io                 ),
    ExecutableProduct("qemu-m68k"               , :qemu_m68k               ),
    ExecutableProduct("qemu-microblaze"         , :qemu_microblaze         ),
    ExecutableProduct("qemu-microblazeel"       , :qemu_microblazeel       ),
    ExecutableProduct("qemu-mips"               , :qemu_mips               ),
    ExecutableProduct("qemu-mips64"             , :qemu_mips64             ),
    ExecutableProduct("qemu-mips64el"           , :qemu_mips64el           ),
    ExecutableProduct("qemu-mipsel"             , :qemu_mipsel             ),
    ExecutableProduct("qemu-mipsn32"            , :qemu_mipsn32            ),
    ExecutableProduct("qemu-mipsn32el"          , :qemu_mipsn32el          ),
    ExecutableProduct("qemu-nbd"                , :qemu_nbd                ),
    ExecutableProduct("qemu-nios2"              , :qemu_nios2              ),
    ExecutableProduct("qemu-or1k"               , :qemu_or1k               ),
    ExecutableProduct("qemu-ppc"                , :qemu_ppc                ),
    ExecutableProduct("qemu-ppc64"              , :qemu_ppc64              ),
    ExecutableProduct("qemu-ppc64le"            , :qemu_ppc64le            ),
    ExecutableProduct("qemu-riscv32"            , :qemu_riscv32            ),
    ExecutableProduct("qemu-riscv64"            , :qemu_riscv64            ),
    ExecutableProduct("qemu-s390x"              , :qemu_s390x              ),
    ExecutableProduct("qemu-sh4"                , :qemu_sh4                ),
    ExecutableProduct("qemu-sh4eb"              , :qemu_sh4eb              ),
    ExecutableProduct("qemu-sparc"              , :qemu_sparc              ),
    ExecutableProduct("qemu-sparc32plus"        , :qemu_sparc32plus        ),
    ExecutableProduct("qemu-sparc64"            , :qemu_sparc64            ),
    ExecutableProduct("qemu-x86_64"             , :qemu_x86_64             ),
    ExecutableProduct("qemu-xtensa"             , :qemu_xtensa             ),
    ExecutableProduct("qemu-xtensaeb"           , :qemu_xtensaeb           ),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Pixman_jll"; compat="0.42.2, 0.43.4"),
    Dependency("Glib_jll"; compat="2.68.1"),
    Dependency("PCRE_jll"),
    BuildDependency("Gettext_jll"),
    Dependency("libcap_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6",
               lock_microarchitecture=false)
