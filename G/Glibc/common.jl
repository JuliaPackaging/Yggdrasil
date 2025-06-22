function glibc_sources(version)
    glibc_version_sources = Dict{VersionNumber,Vector}(
        v"2.12.2" => [
            ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.12.2.tar.xz",
                          "0eb4fdf7301a59d3822194f20a2782858955291dd93be264b8b8d4d56f87203f"),
        ],
        v"2.17" => [
            ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.17.tar.xz",
                          "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e"),
        ],
        v"2.19" => [
            ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.19.tar.xz",
                          "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2"),
        ],
        v"2.33" => [
            ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.33.tar.xz",
                          "2e2556000e105dbd57f0b6b2a32ff2cf173bde4f0d85dffccfd8b7e51a0677ff"),
        ],
        v"2.34" => [
            ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.34.tar.xz",
                          "44d26a1fe20b8853a48f470ead01e4279e869ac149b195dda4e44a195d981ab2"),
        ],
        v"2.38" => [
            ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-2.38.tar.xz",
                          "fb82998998b2b29965467bc1b69d152e9c307d2cf301c9eafb4555b770ef3fd2"),
        ],
    )
    return [
        glibc_version_sources[version]...,
        # We've got a bevvy of patches for Glibc, include them in.
        DirectorySource("./bundled"; follow_symlinks=true),
    ]
end

function glibc_script()
    return raw"""
    cd $WORKSPACE/srcdir/glibc-*/

    # Install licenses first thing
    install_license COPYING* LICENSES

    # Update configure scripts to work well with `musl`
    update_configure_scripts

    for p in ${WORKSPACE}/srcdir/patches/glibc-*.patch; do
        atomic_patch -p1 ${p}
    done

    # Various configure overrides
    GLIBC_CONFIGURE_OVERRIDES=( libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes )

    mkdir -p $WORKSPACE/srcdir/glibc_build

    if [[ -d ../debian ]]; then
        echo "https://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories
        apk update
        apk add quilt
        QUILT_PATCHES=$PWD/../debian/patches quilt push
        echo "libdir = /usr/lib/${target}" >> $WORKSPACE/srcdir/glibc_build/configparms
        echo "slibdir = /lib/${target}" >> $WORKSPACE/srcdir/glibc_build/configparms
        echo "rtlddir = /lib" >> $WORKSPACE/srcdir/glibc_build/configparms
        if [[ ${target} == aarch64-linux-gnu ]]; then
            # At the moment -moutline-atomics (as used in the official debian binaries)
            # intermittently causes binaries that are incompatible with rr. Forcing ARM
            # 8.3 will result in inlined LSE atomics, working around the issue.
            GLIBC_CONFIGURE_OVERRIDES+=( CFLAGS="-march=armv8.3-a -mno-outline-atomics -O2")
        fi
    fi

    # We have problems with libssp on ppc64le
    if [[ ${COMPILER_TARGET} == powerpc64le-* ]]; then
        GLIBC_CONFIGURE_OVERRIDES+=( libc_cv_ssp=no libc_cv_ssp_strong=no )
    fi

    cd $WORKSPACE/srcdir/glibc_build
    $WORKSPACE/srcdir/glibc-*/configure \
        --prefix=/usr \
        --build=${MACHTYPE} \
        --host=${target} \
        --disable-multilib \
        --disable-werror \
        "${GLIBC_CONFIGURE_OVERRIDES[@]}"

    make -j${nproc}

    # Install to the main prefix and also to the sysroot.
    make install install_root=${prefix}
    """
end

function glibc_platforms(version)
    # Start with all glibc platforms
    platforms = filter(p -> libc(p) == "glibc", supported_platforms(;experimental=true))

    # Whittle down the platforms, depending on the minimum supported version of each
    function min_arch_version!(platforms, version, min_version, arches)
        if version < min_version
            filter!(p -> arch(p) ∉ arches, platforms)
        end
    end

    # v2.12.2 is the minimum version for x86_64, i686 support
    min_arch_version!(platforms, version, v"2.12.2", ("x86_64", "i686"))

    # v2.17 is the minimum version for ppc64le support
    min_arch_version!(platforms, version, v"2.17", ("powerpc64le",))

    # v2.19 is the minimum version of ARM support
    min_arch_version!(platforms, version, v"2.19", ("armv7l", "armv6l", "aarch64"))

    return platforms
end

function glibc_products()
    return Product[
        LibraryProduct("libc", :libc; dont_dlopen=true),
        LibraryProduct("libdl", :libld; dont_dlopen=true),
        LibraryProduct("libm", :libm; dont_dlopen=true),
        LibraryProduct("libpthread", :libpthread; dont_dlopen=true),
        LibraryProduct("librt", :librt; dont_dlopen=true),
    ]
end

function glibc_dependencies()
    return []
end
