using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

name = "LibUnwind"
version = v"1.8.2"

# Collection of sources required to build libunwind
sources = [
    ArchiveSource("https://github.com/libunwind/libunwind/releases/download/v$(version)/libunwind-$(version).tar.gz",
                  "7f262f1a1224f437ede0f96a6932b582c8f5421ff207c04e3d9504dfa04c8b82"),
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

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-disable-initial-exec-tls.patch

if [[ "${target}" == aarch64-*-freebsd* ]]; then
    # https://github.com/libunwind/libunwind/issues/873#issuecomment-2912205211
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-freebsd-aarch64.patch
fi

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

export CFLAGS="-DPI -fPIC"
if [[ "${target}" == aarch64-linux-* ]]; then
    # Define macro introduced in later Linux kernel than what we have in the RootFS.
    CFLAGS="${CFLAGS} -DNT_ARM_PAC_MASK=0x406"
fi
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --libdir=${libdir} \
    --enable-debug_frame \
    --enable-minidebuginfo \
    --enable-zlibdebuginfo \
    --disable-tests \
    --disable-conservative-checks \
    --enable-per-thread-cache
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

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    BuildDependency(PackageSpec(name="XZ_jll",
                                uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800",
                                version=v"5.8.1")),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll",
                                uuid="4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version=llvm_version);
                    platforms=filter(p -> sanitize(p) == "memory", platforms)),
]

# Build the tarballs. Note that libunwind started using `stdatomic.h`, which is only
# available with GCC version 4.9 or later, so we need to set a higher preferred version
# than the default.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"11",
               preferred_llvm_version=llvm_version)
