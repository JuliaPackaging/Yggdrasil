using BinaryBuilder

name = "LibUnwind"
version = v"1.7.2"

# Collection of sources required to build libunwind
sources = [
    ArchiveSource("https://github.com/libunwind/libunwind/releases/download/v$(version)/libunwind-$(version).tar.gz",
                  "a18a6a24307443a8ace7a8acc2ce79fbbe6826cd0edf98d6326d0225d6a5d6e6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libunwind*/

atomic_patch -p0 ${WORKSPACE}/srcdir/patches/libunwind-configure-static-lzma.patch
if [[ ${target} == aarch64-linux-musl ]]; then
    # https://github.com/checkpoint-restore/criu/issues/934, fixed by
    # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit?id=9966a05c7b80f075f2bc7e48dbb108d3f2927234
    pushd /opt/aarch64-linux-musl/aarch64-linux-musl/sys-root/usr/include
    atomic_patch -p5 ${WORKSPACE}/srcdir/patches/linux-disentangle_sigcontext.patch
    popd
fi
# https://github.com/JuliaLang/julia/issues/51467, and
# https://github.com/JuliaLang/julia/issues/51465, caused by
# https://github.com/libunwind/libunwind/pull/203
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-revert_prelink_unwind.patch

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

export CFLAGS="-DPI -fPIC"
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --libdir=${libdir} \
    --enable-minidebuginfo \
    --enable-zlibdebuginfo \
    --disable-tests \
    --disable-conservative-checks
make -j${nproc}
make install

# Shoe-horn liblzma.a into libunwind.a
mkdir -p unpacked/{liblzma,libunwind}
(cd unpacked/liblzma; ar -x ${prefix}/lib/liblzma.a)
(cd unpacked/libunwind; ar -x ${prefix}/lib/libunwind.a)
rm -f ${prefix}/lib/libunwind.a
ar -qc ${prefix}/lib/libunwind.a unpacked/**/*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  libunwind is only used
# on Linux or FreeBSD (e.g. ELF systems)
platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libunwind", :libunwind),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("XZ_jll"),
    Dependency("Zlib_jll"),
    BuildDependency("LLVMCompilerRT_jll"; platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
]

# Build the tarballs. Note that libunwind started using `stdatomic.h`, which is only
# available with GCC version 4.9 or later, so we need to set a higher preferred version
# than the default.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"5")
