# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# The AppImage type 2 runtime: the ELF that is prepended to a squashfs image to form an
# AppImage. It mounts the appended filesystem through FUSE and executes AppRun from the mount
# point, so an application is run without ever being unpacked.
name = "AppImageRuntime"
version = v"2025.11.8"

# libfuse, squashfuse and zstd are built here rather than taken from their own JLLs, mirroring how
# upstream builds the runtime. Two reasons:
#
#  * the runtime is fully static, and needs static archives of all of them. Zstd_jll ships only
#    libzstd.so, with no archive to link against, so zstd is built here too;
#  * libfuse is patched so that `fusermount3` is located through $FUSERMOUNT_PROG instead of a
#    path fixed at compile time. That patch is specific to AppImage — a general purpose libfuse
#    should not carry it — so it is applied to a private copy here.
sources = [
    GitSource("https://github.com/AppImage/type2-runtime.git",
              "dd6cebedcbddde9c82f89b011e8e1d40b6e43868"),
    ArchiveSource("https://github.com/libfuse/libfuse/releases/download/fuse-3.15.0/fuse-3.15.0.tar.xz",
                  "70589cfd5e1cff7ccd6ac91c86c01be340b227285c5e200baa284e401eea2ca0"),
    ArchiveSource("https://github.com/vasi/squashfuse/releases/download/0.5.2/squashfuse-0.5.2.tar.gz",
                  "54e4baaa20796e86a214a1f62bab07c7c361fb7a598375576d585712691178f5"),
    ArchiveSource("https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz",
                  "eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3"),
]

script = raw"""
cd ${WORKSPACE}/srcdir

install_license type2-runtime/LICENSE

# The vendored dependencies are staged outside ${prefix} so the shipped artifact contains the
# runtime alone, rather than the static archives and headers used to build it.
DEPS=${WORKSPACE}/deps

export CFLAGS="-ffunction-sections -fdata-sections -Os"

# zstd, static. Built before squashfuse so its configure finds the archive.
cd ${WORKSPACE}/srcdir/zstd-1.5.7
make -C lib -j${nproc} libzstd.a
install -Dm644 lib/libzstd.a ${DEPS}/lib/libzstd.a
install -Dm644 lib/zstd.h lib/zdict.h lib/zstd_errors.h -t ${DEPS}/include

export PKG_CONFIG_PATH="${DEPS}/lib/pkgconfig:${PKG_CONFIG_PATH}"

# libfuse, static, with the AppImage patch that resolves fusermount3 from $FUSERMOUNT_PROG
cd ${WORKSPACE}/srcdir/fuse-3.15.0
patch -p1 < ${WORKSPACE}/srcdir/type2-runtime/patches/libfuse/mount.c.diff

# libfuse probes at configure time whether getmntent unescapes, by *running* a test binary. Meson
# cannot do that when cross compiling, so the probe is removed and its outcome supplied directly:
# every platform here is musl, and on musl the probe reports that escaping is needed.
sed -i '/^result = cc.run(detect_getmntent_needs_unescape)/,/^endif$/d' meson.build

CFLAGS="${CFLAGS} -DGETMNTENT_NEEDS_UNESCAPING" \
meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release \
    --prefix=${DEPS} --default-library=static \
    -Dexamples=false -Dtests=false -Dutils=false
meson compile -C build -j${nproc}
meson install -C build

# squashfuse, static. The runtime uses the low level (_ll) interface.
cd ${WORKSPACE}/srcdir/squashfuse-0.5.2
# zstd lives in ${DEPS} and installs no pkg-config file, so its location has to be given
# explicitly. Without it configure silently builds squashfuse without zstd support, and the
# resulting runtime fails to mount any zstd compressed AppImage.
./configure --prefix=${DEPS} --host=${target} \
    --disable-shared --enable-static \
    --with-zlib=${prefix} --with-zstd=${DEPS} \
    --without-lzo --without-lz4 --without-xz
make -j${nproc}
make install
# The runtime includes private headers that `make install` does not ship
install -Dm644 ./*.h -t ${DEPS}/include/squashfuse

# The runtime itself.
cd ${WORKSPACE}/srcdir/type2-runtime/src/runtime

# The link is done directly rather than through upstream's Makefile, which hardcodes clang and
# absolute include paths. Upstream additionally links mimalloc purely as an allocator
# optimisation; it is left out so the build stays limited to the sources carried here.
#
# GIT_COMMIT is single quoted so the inner double quotes survive: a raw Julia string turns \" into
# a bare quote, which the shell would then consume, leaving GCC a bare identifier.
# runtime.c includes <squashfuse/ll.h>, so ${DEPS}/include has to be on the search path in its own
# right. It is not added implicitly the way ${prefix}/include is.
${CC} -I${DEPS}/include -I${DEPS}/include/squashfuse -I${DEPS}/include/fuse3 \
    -std=gnu99 -Os -D_FILE_OFFSET_BITS=64 \
    -DGIT_COMMIT='"dd6cebedcbddde9c82f89b011e8e1d40b6e43868"' \
    -T data_sections.ld -ffunction-sections -fdata-sections -Wl,--gc-sections \
    -static \
    runtime.c \
    -L${DEPS}/lib -L${prefix}/lib -lsquashfuse -lsquashfuse_ll -lzstd -lz -lfuse3 -lpthread -ldl \
    -o runtime

strip --strip-debug --strip-unneeded runtime

# The "classic" magic bytes cannot be placed by the linker script and have to be written after
# stripping, since objcopy and strip rewrite the header. AppImage tooling identifies a file as an
# AppImage by these three bytes at offset 8.
printf 'AI\x02' | dd of=runtime bs=1 count=3 seek=8 conv=notrunc

install -Dm755 runtime ${bindir}/runtime
"""

# The runtime has to run on any Linux the AppImage is copied to, so it is built fully static.
# While musl is preferred for static linking (and used by upstream), we build for all supported Linux
# platforms (including gnu) so that the JLL is installable by Pkg on standard gnu systems.
platforms = filter(Sys.islinux, supported_platforms())

products = [
    ExecutableProduct("runtime", :runtime),
]

# Zlib_jll ships libz.a, so it can be linked statically as a normal dependency. Zstd_jll ships
# only a shared library, which is why zstd is built from source above.
dependencies = [
    Dependency("Zlib_jll"),
]

# The runtime is prepended to every AppImage built with it, so its size is paid on each one.
# BinaryBuilder's default compiler is old enough that dead code elimination barely fires here:
# the same sources give a 2.76 MB binary with the default and 668 KB with GCC 9, measured on
# x86_64-linux-musl.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version = v"12")
