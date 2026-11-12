using BinaryBuilder2

# FreeBSDSysroot is the libc sysroot that BinaryBuilder2's `*-unknown-freebsd*` C
# toolchains are built against and ship.  It is a subset of FreeBSD's prebuilt
# `base.txz`: headers, CRT objects, compiler runtimes and the core system libraries.
version = v"14.1"

build_tarballs(;
    src_name = "FreeBSDSysroot",
    src_version = version,
    sources = [
        # `base.txz` contains hardlinks whose targets are not extracted alongside them,
        # which Tar.jl rejects, so we download it as a plain file and extract it with `tar`.
        FileSource("http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/arm64/$(version.major).$(version.minor)-RELEASE/base.txz",
                   "b25830252e0dce0161004a5b69a159cbbd92d5e92ae362b06158dbb3f2568d32";
                   target="freebsd-aarch64.tar.xz"),
        FileSource("http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/amd64/$(version.major).$(version.minor)-RELEASE/base.txz",
                   "bb451694e8435e646b5ff7ddc5e94d5c6c9649f125837a34b2a2dd419732f347";
                   target="freebsd-x86_64.tar.xz"),
    ],
    script = raw"""
    TARBALL_NAME="freebsd-${target%%-*}.tar.xz"

    FILES_TO_EXTRACT=(
        ./usr/include

        # CRT objects
        ./usr/lib/Scrt1.o
        ./usr/lib/crti.o
        ./usr/lib/crtbeginS.o
        ./usr/lib/crtendS.o
        ./usr/lib/crtn.o
        ./usr/lib/crtbegin.o
        ./usr/lib/crtend.o
        ./usr/lib/crtbeginT.o
        ./usr/lib/gcrt1.o
        ./usr/lib/crt1.o

        # Compiler runtimes.  libc++'s own `.so`/`.a` and headers are omitted because
        # they conflict with the LLVM libc++ that the toolchain ships.
        ./usr/lib/libcompiler_rt.a
        ./usr/lib/libgcc.a
        ./usr/lib/libgcc_s.so
        ./lib/libgcc_s.so.1
        ./usr/lib/libgcc_eh.a
        ./lib/libc++.so.1
        ./usr/lib/libcxxrt.a
        ./usr/lib/libcxxrt.so
        ./lib/libcxxrt.so.1

        # The system libraries needed to bootstrap GCC and Clang
        ./lib/libc.so.7
        ./usr/lib/libc.so
        ./usr/lib/libc_nonshared.a
        ./usr/lib/libdl.so.1
        ./usr/lib/libdl.so
        ./lib/libm.so.5
        ./usr/lib/libm.so
        ./lib/libthr.so.3
        ./usr/lib/libthr.so
        ./usr/lib/libpthread.so
        ./usr/lib/libpthread.a
        ./usr/lib/libthr.a
    )

    tar -C ${prefix} -xJf "${TARBALL_NAME}" "${FILES_TO_EXTRACT[@]}"

    # These headers are provided by the libc++, libunwind and zlib JLLs instead
    rm -rf ${prefix}/usr/include/c++
    rm -f ${prefix}/usr/include/{__libunwind_config.h,unwind_arm_ehabi.h,libunwind.h}
    rm -f ${prefix}/usr/include/{zconf.h,zlib.h}

    tar -xJf "${TARBALL_NAME}" ./COPYRIGHT
    install_license COPYRIGHT
    """,
    platforms = [
        Platform("x86_64", "freebsd"; os_version="$(version.major).$(version.minor)"),
        Platform("aarch64", "freebsd"; os_version="$(version.major).$(version.minor)"),
    ],
    products = [
        FileProduct("usr/include/unistd.h", :unistd_h),
        # FreeBSD's libc must not be loaded into a running process
        LibraryProduct(["lib/libc"], :libc; dont_dlopen=true),
    ],
    # Nothing is compiled, we only unpack FreeBSD's prebuilt base system
    host_toolchains = [HostToolsToolchain()],
    target_toolchains = [],
)
