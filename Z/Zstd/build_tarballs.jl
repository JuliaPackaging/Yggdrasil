using BinaryBuilder

name = "Zstd"
version = v"1.6.0"

sources = [
    ArchiveSource("https://github.com/facebook/zstd/releases/download/v$(version)/zstd-$(version).tar.gz",
                  "2ba599ae2a257976278e7e71e998433a387bfd18aa7b78678229fd5d84f5e9b8"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/zstd-*

mkdir build-zstd && cd build-zstd

if [[ "${target}" == *86*-linux-gnu ]]; then
    # Using `clock_gettime` on old Glibc requires linking to `librt`.
    sed -ri "s/^c_link_args = \[(.*)\]/c_link_args = [\1, '-lrt']/" ${MESON_TARGET_TOOLCHAIN}
elif [[ "${target}" == *musl* ]]; then
    # zstd uses `qsort_r` which is not available from our (old) musl
    # <https://github.com/facebook/zstd/issues/4311>. Use the plain C90 `qsort` instead.
    sed -ri "s/^c_args = \[(.*)\]/c_args = [\1, '-DZDICT_QSORT=ZDICT_QSORT_C90']/" ${MESON_TARGET_TOOLCHAIN}
elif [[ "${target}" == i686-*-mingw* ]]; then
    # Using `WakeConditionVariable`/`InitializeConditionVariable`/`SleepConditionVariableCS`
    # require Windows Vista:
    # <https://learn.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-wakeconditionvariable>.
    sed -ri "s/^c_args = \[(.*)\]/c_args = [\1, '-D_WIN32_WINNT=_WIN32_WINNT_VISTA']/" ${MESON_TARGET_TOOLCHAIN}
fi

if [[ "${target}" == *-mingw* ]]; then
    # Builds of libzstd-1.dll made with older binutils also exported the mingw-w64 CRT
    # replacements below, and current builds of libLLVM, llvm-config and LLD import them
    # from (i.e. expect them to be in) libzstd-1.dll.
    #
    # Newer binutils no longer export them by default, which makes those libraries fail to load.
    # To remain backward compatible, we export these symbols explicitly. A `.def` file turns off
    # default exporting, so `--export-all-symbols` keeps everything else exported.
    cat > ${WORKSPACE}/srcdir/crt-compat.def << 'EOF'
EXPORTS
    mbrlen
    mbrtowc
    mbsrtowcs
    wcrtomb
    wcsrtombs
EOF
    sed -ri "s|^c_link_args = \[(.*)\]|c_link_args = [\1, '-Wl,--export-all-symbols', '${WORKSPACE}/srcdir/crt-compat.def']|" ${MESON_TARGET_TOOLCHAIN}
fi

meson --cross-file="${MESON_TARGET_TOOLCHAIN}" ../build/meson

# Meson beautifully forces thin archives, without checking whether the dynamic linker
# actually supports them: <https://github.com/mesonbuild/meson/issues/10823>.  Let's remove
# the (deprecated...) `T` option to `ar`, until they fix it in Meson.
sed -i.bak 's/csrDT/csrD/' build.ninja

ninja -j${nproc}
ninja install

if [[ "${target}" == *-mingw* ]]; then
    # Make sure the compatibility exports are really there (i686 symbols have an extra `_`)
    for sym in mbrlen mbrtowc mbsrtowcs wcrtomb wcsrtombs; do
        nm ${prefix}/lib/libzstd.dll.a | grep -Eq " __imp__?${sym}$" ||
            { echo "libzstd-1.dll does not export ${sym}"; exit 1; }
    done
fi
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzstd", :libzstd),
    ExecutableProduct("zstd", :zstd),
    ExecutableProduct("zstdmt", :zstdmt),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6",
               # Windows relocatable PE requires binutils >= 2.36
               preferred_gcc_version=v"11")
