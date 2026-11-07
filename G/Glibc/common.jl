# Shared pieces of the Glibc recipes.  These produce the glibc sysroots
# that BinaryBuilder2's `CToolchain` installs, so the layout (everything in `/lib`,
# headers in `/usr/include`, relative linker scripts, `crt*.o` alongside) matters.

function glibc_sources(version)
    hashes = Dict(
        v"2.17" => "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e",
        v"2.19" => "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2",
        v"2.34" => "44d26a1fe20b8853a48f470ead01e4279e869ac149b195dda4e44a195d981ab2",
    )
    tarball = "glibc-$(version.major).$(version.minor).tar.xz"
    return [
        # Mirrors are tried in order
        ArchiveSource([
                "https://mirrors.kernel.org/gnu/glibc/$(tarball)",
                "https://ftpmirror.gnu.org/glibc/$(tarball)",
                "https://mirrors.ocf.berkeley.edu/gnu/glibc/$(tarball)",
                "https://ftp.gnu.org/gnu/glibc/$(tarball)",
            ],
            hashes[version]),
        DirectorySource("./bundled"; follow_symlinks=true),
    ]
end

function glibc_platforms(version)
    arches = Dict(
        v"2.17" => ["x86_64", "i686", "powerpc64le"],
        v"2.19" => ["x86_64", "i686", "armv7l", "armv6l", "aarch64", "powerpc64le"],
        v"2.34" => ["x86_64", "i686", "armv7l", "armv6l", "aarch64", "powerpc64le"],
    )
    return [Platform(arch, "linux") for arch in arches[version]]
end

const glibc_script = raw"""
cd ${WORKSPACE}/srcdir/glibc-*/
install_license COPYING* LICENSES

update_configure_scripts

for p in ${WORKSPACE}/srcdir/patches/glibc-*.patch; do
    atomic_patch -p1 ${p}
done

GLIBC_CONFIGURE_OVERRIDES=( libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes BUILD_CC=${HOSTCC} )

# We have problems with libssp on ppc64le
if [[ ${target} == powerpc64le-* ]]; then
    GLIBC_CONFIGURE_OVERRIDES+=( libc_cv_ssp=no libc_cv_ssp_strong=no )
fi

# Always use `/lib`, never `/lib64`
GLIBC_CONFIGURE_OVERRIDES+=( libc_cv_slibdir=/lib libdir=/lib )

# Newer compilers balk at this old code: `-Wno-implicit-int` fixes configure tests
# declaring `__start()` without a return type, and `-fcommon` restores the GCC <= 10
# behavior of merging the multiple definitions of `__cache_line_size`.
GLIBC_CONFIGURE_OVERRIDES+=( CFLAGS="-g -O2 -fcommon -Wno-implicit-int -Wno-implicit-function-declaration -Wno-builtin-declaration-mismatch -Wno-array-parameter -Wno-int-conversion" )

mkdir -p ${WORKSPACE}/srcdir/glibc_build
cd ${WORKSPACE}/srcdir/glibc_build
${WORKSPACE}/srcdir/glibc-*/configure \
    --prefix=/usr \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-multilib \
    --disable-werror \
    "${GLIBC_CONFIGURE_OVERRIDES[@]}"

make -j${nproc}
make install install_root="${prefix}"

# GCC's bootstrap needs the startup objects next to the libraries
cp csu/crt1.o csu/crti.o csu/crtn.o ${prefix}/lib/

# Make the linker scripts relative so the sysroot can live anywhere
for f in ${prefix}/lib/*.so; do
    if [[ -f ${f} ]] && [[ ! -L ${f} ]] && grep -q "GNU ld script" ${f}; then
        sed -i -e "s& /lib/& ./&g" ${f}
    fi
done

# Some files get installed under `${prefix}/${prefix}`
if [[ -d ${prefix}/${prefix} ]]; then
    mv -v ${prefix}/${prefix}/* ${prefix}/
    rm -rf ${prefix}/workspace
fi
"""

function glibc_products(version)
    # These libraries make up a C runtime of their own, and loading them into a running
    # process (which already has its own libc and dynamic loader) crashes it.  Mark them
    # `dont_dlopen` so that JLL wrappers don't load them eagerly on Julia versions
    # without `LazyLibrary` support.
    # The unversioned `.so` files are linker scripts, so point at the real libraries.
    # From v2.34 on, glibc installs those under their sonames instead of `lib*-2.xx.so`.
    if version >= v"2.34"
        return [
            LibraryProduct(["lib/ld-linux-x86-64.so.2", "lib/ld-linux.so.2",
                            "lib/ld-linux-aarch64.so.1", "lib/ld-linux-armhf.so.3",
                            "lib/ld64.so.2"], :ld; dont_dlopen=true),
            LibraryProduct("lib/libc.so.6", :libc; dont_dlopen=true),
            LibraryProduct("lib/libdl.so.2", :libdl; dont_dlopen=true),
            LibraryProduct("lib/libm.so.6", :libm; dont_dlopen=true),
            LibraryProduct("lib/libpthread.so.0", :libpthread; dont_dlopen=true),
            LibraryProduct("lib/librt.so.1", :librt; dont_dlopen=true),
            LibraryProduct("lib/libresolv.so.2", :libresolv; dont_dlopen=true),
            LibraryProduct("lib/libutil.so.1", :libutil; dont_dlopen=true),
        ]
    end
    v = "$(version.major).$(version.minor)"
    return [
        LibraryProduct("lib/ld-$(v)", :ld; dont_dlopen=true),
        LibraryProduct("lib/libc-$(v)", :libc; dont_dlopen=true),
        LibraryProduct("lib/libdl-$(v)", :libdl; dont_dlopen=true),
        LibraryProduct("lib/libm-$(v)", :libm; dont_dlopen=true),
        LibraryProduct("lib/libpthread-$(v)", :libpthread; dont_dlopen=true),
        LibraryProduct("lib/librt-$(v)", :librt; dont_dlopen=true),
        LibraryProduct("lib/libresolv-$(v)", :libresolv; dont_dlopen=true),
        LibraryProduct("lib/libutil-$(v)", :libutil; dont_dlopen=true),
    ]
end

function glibc_build_tarballs(version)
    return build_tarballs(;
        src_name = "Glibc",
        src_version = version,
        sources = glibc_sources(version),
        script = glibc_script,
        platforms = glibc_platforms(version),
        products = glibc_products(version),
        host_toolchains = [CToolchain(; vendor=:bootstrap), HostToolsToolchain()],
        target_toolchains = [CToolchain(; vendor=:bootstrap)],
    )
end
