# Shared pieces of the BinaryBuilder2 Glibc recipes.  These produce the glibc sysroots
# that BinaryBuilder2's `CToolchain` installs, so the layout (everything in `/lib`,
# headers in `/usr/include`, relative linker scripts, `crt*.o` alongside) matters.
# `common.jl` is still used by the BinaryBuilder1 recipes.

function glibc_bb2_sources(version)
    hashes = Dict(
        v"2.17" => "6914e337401e0e0ade23694e1b2c52a5f09e4eda3270c67e7c3ba93a89b5b23e",
        v"2.19" => "2d3997f588401ea095a0b27227b1d50cdfdd416236f6567b564549d3b46ea2a2",
    )
    return [
        ArchiveSource("https://mirrors.kernel.org/gnu/glibc/glibc-$(version.major).$(version.minor).tar.xz",
                      hashes[version]),
        DirectorySource("./bundled"; follow_symlinks=true),
    ]
end

function glibc_bb2_platforms(version)
    arches = Dict(
        v"2.17" => ["x86_64", "i686", "powerpc64le"],
        v"2.19" => ["x86_64", "i686", "armv7l", "armv6l", "aarch64", "powerpc64le"],
    )
    return [Platform(arch, "linux") for arch in arches[version]]
end

const glibc_bb2_script = raw"""
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
sed -i -e "s& /lib/& ./&g" ${prefix}/lib/libc.so ${prefix}/lib/libpthread.so

# Some files get installed under `${prefix}/${prefix}`
if [[ -d ${prefix}/${prefix} ]]; then
    mv -v ${prefix}/${prefix}/* ${prefix}/
    rm -rf ${prefix}/workspace
fi
"""

function glibc_bb2_products(version)
    # The unversioned `.so` files are linker scripts, so point at the real libraries
    v = "$(version.major).$(version.minor)"
    return [
        LibraryProduct("lib/ld-$(v)", :ld),
        LibraryProduct("lib/libc-$(v)", :libc),
        LibraryProduct("lib/libdl-$(v)", :libdl),
        LibraryProduct("lib/libm-$(v)", :libm),
        LibraryProduct("lib/libpthread-$(v)", :libpthread),
        LibraryProduct("lib/librt-$(v)", :librt),
        LibraryProduct("lib/libresolv-$(v)", :libresolv),
        LibraryProduct("lib/libutil-$(v)", :libutil),
    ]
end

function glibc_bb2_build_tarballs(version)
    return build_tarballs(;
        src_name = "Glibc",
        src_version = version,
        sources = glibc_bb2_sources(version),
        script = glibc_bb2_script,
        platforms = glibc_bb2_platforms(version),
        products = glibc_bb2_products(version),
        host_toolchains = [CToolchain(; vendor=:bootstrap), HostToolsToolchain()],
        target_toolchains = [CToolchain(; vendor=:bootstrap)],
    )
end
