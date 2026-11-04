using BinaryBuilder2

# Musl is the libc sysroot that BinaryBuilder2's `*-linux-musl*` C toolchains are
# built against and ship, so we install the full `usr/` tree (headers, CRT objects,
# static and shared libraries), plus the dynamic loader in `lib/`.
version = v"1.2.6"

build_tarballs(;
    src_name = "Musl",
    src_version = version,
    sources = [
        # Mirrors are tried in order; musl.libc.org is slow and often times out.
        ArchiveSource([
                "https://sources.buildroot.net/musl/musl-$(version).tar.gz",
                "https://sources.openwrt.org/musl-$(version).tar.gz",
                "https://distfiles.macports.org/musl/musl-$(version).tar.gz",
                "https://musl.libc.org/releases/musl-$(version).tar.gz",
            ],
            "d585fd3b613c66151fc3249e8ed44f77020cb5e6c1e635a616d3f9f82460512a"),
    ],
    script = raw"""
    mkdir ${WORKSPACE}/srcdir/musl_build
    cd ${WORKSPACE}/srcdir/musl_build

    musl_arch()
    {
        case "${target}" in
            i686*)
                echo i386 ;;
            arm*)
                echo armhf ;;
            *)
                echo ${target%%-*} ;;
        esac
    }

    # Force an SONAME with a version number
    export LDFLAGS="-Wl,-soname,libc.musl-$(musl_arch).so.1"
    ${WORKSPACE}/srcdir/musl-*/configure --prefix=/usr \
        --build=${MACHTYPE} \
        --host=${target} \
        --disable-multilib \
        --disable-werror \
        --enable-optimize \
        --enable-debug \
        --disable-gcc-wrapper

    make -j${nproc}
    make install DESTDIR="${prefix}"

    # `make install` points the loader at the absolute path `/usr/lib/libc.so`,
    # make it relative so it resolves within the prefix.  Also provide the SONAME.
    ln -sfv ../usr/lib/libc.so ${prefix}/lib/ld-musl-$(musl_arch).so.1
    ln -sfv libc.so ${prefix}/usr/lib/libc.musl-$(musl_arch).so.1

    install_license ${WORKSPACE}/srcdir/musl-*/COPYRIGHT
    """,
    platforms = [
        Platform("x86_64", "linux"; libc="musl"),
        Platform("i686", "linux"; libc="musl"),
        Platform("aarch64", "linux"; libc="musl"),
        Platform("armv6l", "linux"; libc="musl"),
        Platform("armv7l", "linux"; libc="musl"),
    ],
    products = [
        LibraryProduct(["usr/lib/libc"], :libc),
    ],
    # Use the bootstrap toolchain, since this is part of building the toolchain itself
    host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:bootstrap)],
)

# Build trigger: 2
