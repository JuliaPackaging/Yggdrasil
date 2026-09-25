# Native GCC toolchains, used by Julia's CI images (JuliaCI/rootfs-images'
# `package_linux`), where they are installed at `/usr/local`, and on Windows to build
# code against the same C and C++ runtime that Julia ships.
#
# Each tarball is a complete compiler for one platform that runs on, and targets, that
# same platform (host == target): GCC, binutils, and a sysroot with the C library.
# - Linux: an old glibc (that of the GCCBootstrap shards: 2.17, or 2.19 on
#   aarch64/armv7l) and Linux kernel headers, so that everything it builds runs on old
#   distributions.
# - Windows: the MinGW-w64 headers, CRT and winpthreads of the GCCBootstrap shards, in
#   GCC's default MinGW layout (`<sysroot>/mingw/{include,lib}`), which Clang's MinGW
#   driver also finds when given the installation as `--sysroot`. The host executables
#   are linked statically, so that they do not depend on whichever runtime DLLs come
#   first in the search path. Programs are installed without a target prefix
#   (`gcc.exe`), as in other native MinGW toolchains.
#
# The GCC version must never be newer than the one CompilerSupportLibraries_jll (CSL)
# is built with, because Julia ships CSL's libstdc++/libgcc_s/libgfortran and binaries
# built against newer GCC headers could need symbols that runtime lacks. We use exactly
# that version: sources and patches are those of `0_RootFS/GCCBootstrap@15` (the
# shards CSL v1.5 is built from), code generation options are the same as in
# `0_RootFS/gcc_common.jl`, and the target runtime libraries are built by those very
# shards; the build fails if libstdc++'s configuration differs from theirs.
# Bump this recipe together with CSL, never before.

using BinaryBuilder

include("../../0_RootFS/gcc_sources.jl")

name = "GCCToolchain"
version = v"15.2.0"

sources = [
    # GCC, its dependencies and binutils, as for the GCCBootstrap shards. Not their C
    # library sources: we ship the shards' sysroot.
    filter(s -> !(s isa DirectorySource) && !occursin(r"/glibc-", s.url),
           gcc_sources(version, Platform("x86_64", "linux")))...,
    DirectorySource("../../0_RootFS/GCCBootstrap@15/bundled"; follow_symlinks=true),
    # The kernel headers of the previous (GCC 9) toolchain of Julia's CI images, newer
    # than the shards' (4.20.9)
    ArchiveSource("https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.14.tar.xz",
                  "2df2b4e71b5b2f25b201ba5a3d42bdf676b1deaae2fb44c14a1d8a33c9f76a4d"),
]

script = "GCC_VERSION=$(version)\n" * raw"""
cd ${WORKSPACE}/srcdir

# We build on ${MACHTYPE} (x86_64-linux-musl) a compiler that runs on ${target}
# and generates code for ${target} (a "Canadian cross" with host == target).
#
# Use the unwrapped GCCBootstrap compilers of the same GCC version, both for the host
# code and for the target runtime libraries: BinaryBuilder's wrappers add flags we do
# not want here (-march, extra library paths, rpath-links). Their sysroot has the
# glibc we build against (2.17 or 2.19 depending on the architecture).
BB_TOOLCHAIN=/opt/${target}/bin/${target}
for tool in CC:gcc CXX:g++ GCC:gcc GFORTRAN:gfortran AR:ar AS:as LD:ld NM:nm \
            RANLIB:ranlib STRIP:strip OBJCOPY:objcopy OBJDUMP:objdump READELF:readelf; do
    export ${tool%%:*}_FOR_TARGET=${BB_TOOLCHAIN}-${tool##*:}
done
export CC=${BB_TOOLCHAIN}-gcc CXX=${BB_TOOLCHAIN}-g++
export AR=${BB_TOOLCHAIN}-ar AS=${BB_TOOLCHAIN}-as LD=${BB_TOOLCHAIN}-ld NM=${BB_TOOLCHAIN}-nm
export RANLIB=${BB_TOOLCHAIN}-ranlib STRIP=${BB_TOOLCHAIN}-strip
export OBJCOPY=${BB_TOOLCHAIN}-objcopy OBJDUMP=${BB_TOOLCHAIN}-objdump READELF=${BB_TOOLCHAIN}-readelf
# GCC's generator programs run on the build machine, where an older libstdc++ comes
# first in the library search path.
export CC_FOR_BUILD=${CC_BUILD} CXX_FOR_BUILD="${CXX_BUILD} -static-libstdc++ -static-libgcc"
unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS FC

sysroot=${prefix}/${target}/sys-root
shard_sysroot=/opt/${target}/${target}/sys-root

if [[ "${target}" == *-mingw* ]]; then
    # Native MinGW toolchains are installed without a target prefix.
    PROGRAM_PREFIX=()
    # Link the host executables statically, including winpthread (which libstdc++
    # and libgcc's unwinder use; -static-libstdc++ alone ends in -Bdynamic before
    # it). Spelled `--static`, because libtool takes `-static` to mean building
    # static libraries only (e.g. no LTO plugin).
    HOST_LDFLAGS="--static"
else
    PROGRAM_PREFIX=(--program-prefix=${target}-)
    HOST_LDFLAGS=
fi


## Sysroot: the C library (from the GCCBootstrap shard), and Linux kernel headers

if [[ "${target}" == *-mingw* ]]; then
    # GCC's MinGW configuration looks for the system headers and libraries in
    # `<sysroot>/mingw`, unless configured otherwise (as the shard is).
    mkdir -p ${sysroot}/mingw ${prefix}/bin
    cp -a ${shard_sysroot}/include ${shard_sysroot}/lib ${sysroot}/mingw/
    # Runtime DLLs (winpthread) go where the programs are, as usual on Windows
    if [[ -d ${shard_sysroot}/bin ]]; then
        cp -a ${shard_sysroot}/bin/*.dll ${prefix}/bin/
    fi
else
    mkdir -p ${sysroot}
    cp -a ${shard_sysroot}/. ${sysroot}/
    # Build leftovers of the shard
    rm -rf ${sysroot}/workspace ${sysroot}/usr/share/{info,man,locale}

    # Replace the shard's (older) kernel headers
    case "${target}" in
        x86_64-*|i686-*) karch=x86 ;;
        aarch64-*) karch=arm64 ;;
        arm*) karch=arm ;;
        powerpc64le-*) karch=powerpc ;;
    esac
    for d in asm asm-generic drm linux misc mtd rdma sound video xen; do
        rm -rf ${sysroot}/usr/include/${d}
    done
    cd ${WORKSPACE}/srcdir/linux-*/
    make ARCH=${karch} HOSTCC=${CC_BUILD} INSTALL_HDR_PATH=${sysroot}/usr headers_install
fi


## Binutils

cd ${WORKSPACE}/srcdir/binutils-*/
mkdir build && cd build
LDFLAGS="${HOST_LDFLAGS}" ../configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --target=${target} \
    --with-sysroot=${sysroot} \
    "${PROGRAM_PREFIX[@]}" \
    --disable-werror \
    --disable-nls \
    --disable-gprofng \
    --disable-install-libbfd \
    --disable-install-libiberty \
    --enable-deterministic-archives
make -j${nproc}
make install
# Remove the development files of binutils' own libraries
rm -rf ${prefix}/include
rm -f ${prefix}/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.*


## GCC

cd ${WORKSPACE}/srcdir/gcc-*/
for proj in gmp mpfr mpc isl; do
    mv ../${proj}-* ${proj}
done

# Do not run fixincludes (as GCCBootstrap)
sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in

# Same patches as GCCBootstrap@15 (its own `bundled` directory), applied the same way:
# the top-level ones opportunistically, the ones in `gcc/` must apply. Except the ones
# that only change the layout: moving the C++ headers to where a cross compiler looks
# for them, and moving MinGW's headers and libraries out of `<sysroot>/mingw` (GCC's
# default, where Clang also looks).
rm ${WORKSPACE}/srcdir/patches/gcc485_triplet_prefixed_cxx_headers.patch
rm ${WORKSPACE}/srcdir/patches/gcc/gcc1520_mingw_include.patch
for p in ${WORKSPACE}/srcdir/patches/gcc*.patch; do
    atomic_patch -p1 "${p}" || true
done
for p in ${WORKSPACE}/srcdir/patches/gcc/*.patch; do
    atomic_patch -p1 "${p}"
done

# Default architectures, as GCCBootstrap (and therefore CSL)
GCC_CONF_ARGS=()
case "${target}" in
    arm*hf) GCC_CONF_ARGS+=(--with-float=hard --with-arch=armv6 --with-fpu=vfp) ;;
    x86_64-*) GCC_CONF_ARGS+=(--with-arch=x86-64) ;;
    i686-*) GCC_CONF_ARGS+=(--with-arch=pentium4) ;;
esac
if [[ "${target}" == *-mingw* ]]; then
    # As GCCBootstrap: libstdc++ without TLS (its std::call_once ABI), and OpenMP
    GCC_CONF_ARGS+=(--disable-tls --enable-libgomp)
fi

# libstdc++ enables NLS (`_GLIBCXX_USE_NLS`) only if `msgfmt` is available, as it is
# in GCCBootstrap's build environment
apk update
apk add gettext

mkdir ${WORKSPACE}/srcdir/gcc_build && cd ${WORKSPACE}/srcdir/gcc_build
LDFLAGS="${HOST_LDFLAGS}" ${WORKSPACE}/srcdir/gcc-*/configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --target=${target} \
    --with-sysroot=${sysroot} \
    "${PROGRAM_PREFIX[@]}" \
    --enable-languages=c,c++,fortran \
    --enable-shared \
    --enable-threads=posix \
    --enable-version-specific-runtime-libs \
    --disable-multilib \
    --disable-bootstrap \
    --disable-werror \
    --disable-libcc1 \
    "${GCC_CONF_ARGS[@]}"
# libstdc++ is configured and built with the target C++ compiler, which in a normal
# build is the in-tree one, without C++ headers. Ours is installed and has its own,
# which would shadow the C library's (e.g. <complex.h>, <math.h>), change the outcome
# of configure checks, and thereby `c++config.h`. (The top-level Makefile clears
# command-line overrides, so edit it.)
sed -i "s|^RAW_CXX_FOR_TARGET=.*|& -nostdinc++|" Makefile
grep '^RAW_CXX_FOR_TARGET=.* -nostdinc++$' Makefile
make -j${nproc}
make install

# With version-specific runtime libraries, libgcc_s still ends up in the OS library
# directory next to GCC's (lib/gcc/<target>/lib64 on 64-bit targets), where the driver
# does not look. Move it next to the other runtime libraries.
gcc_libdir=${prefix}/lib/gcc/${target}/${GCC_VERSION}
for d in ${prefix}/lib/gcc/${target}/lib*; do
    [[ -d "${d}" ]] || continue
    mv ${d}/libgcc_s* ${gcc_libdir}/
    rmdir ${d}
done
# On Windows, the DLL goes one level up instead; put it with the others, next to the
# programs
if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/lib/gcc/${target}/libgcc_s_*.dll ${prefix}/bin/
fi


## Clean up

# As host == target, GCC also installs its drivers as `<target>-<program>`, which the
# program prefix turns into `<target>-<target>-<program>`
rm -f ${prefix}/bin/${target}-${target}-*

# Documentation, misleading libtool archives, and the (empty) include directory
rm -rf ${prefix}/share/{info,man,locale}
find ${prefix}/ -name '*.la' -delete
rmdir ${prefix}/include 2>/dev/null || true

# The C++ library must be configured exactly like the one CompilerSupportLibraries
# ships, i.e. the GCCBootstrap shard's
cmp ${prefix}/lib/gcc/${target}/${GCC_VERSION}/include/c++/${target}/bits/c++config.h \
    /opt/${target}/${target}/include/c++/${GCC_VERSION}/${target}/bits/c++config.h

# Strip the host executables (not the target libraries)
for f in ${prefix}/bin/* ${prefix}/${target}/bin/* ${prefix}/libexec/gcc/${target}/*/*; do
    [[ -f "${f}" && ! -L "${f}" ]] || continue
    [[ "$(basename "${f}")" == lib*.dll ]] && continue
    if file -b "${f}" | grep -q -E '^(ELF|PE32)'; then
        ${STRIP} "${f}"
    fi
done

if [[ "${target}" == *-mingw* ]]; then
    # As on other native MinGW toolchains, and so that `cc` does not find another one
    cp ${prefix}/bin/gcc.exe ${prefix}/bin/cc.exe

    # The host executables and plugins must only import system DLLs (not the runtime
    # DLLs, named lib<name>-<version>.dll, which are target libraries)
    for f in $(find ${prefix}/bin ${prefix}/${target}/bin ${prefix}/libexec ${prefix}/lib/bfd-plugins \
                    -type f \( -name '*.exe' -o -name '*.dll' \) ! -name 'lib*-[0-9]*.dll'); do
        imports=$(${OBJDUMP} -p "${f}" | sed -n 's/^\s*DLL Name: //p' | tr '[:upper:]' '[:lower:]')
        if [[ -z "${imports}" ]]; then
            echo "${f}: no imports found"
            exit 1
        fi
        for dll in ${imports}; do
            case "${dll}" in
                kernel32.dll|msvcrt.dll|advapi32.dll|user32.dll|shell32.dll) ;;
                *) echo "${f} imports ${dll}"; exit 1 ;;
            esac
        done
    done
    # Symbolic links cannot be relied upon on Windows
    if [[ -n "$(find ${prefix}/ -type l)" ]]; then
        find ${prefix}/ -type l -ls
        exit 1
    fi
fi
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# A toolchain to install, not a library to load: no products (as `G/GCCBootstrap`).
products = Product[]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"15", skip_audit=true, julia_compat="1.6")
