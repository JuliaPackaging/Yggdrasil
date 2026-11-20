using BinaryBuilder2

name = "pkgconf"
version = v"3.0.11"

tarball = "pkgconf-$(version).tar.xz"
sources = [
    ArchiveSource(["https://github.com/pkgconf/pkgconf/releases/download/pkgconf-$(version)/$(tarball)",
                   "https://distfiles.ariadne.space/pkgconf/$(tarball)"],
                  "d0cd841bc8e55b9da888106c00dc256d05b7d1d8e5a46f4be4eb4c5125bd2dc4"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/pkgconf-*

# pkgconf compiles its default search paths into the binary.  Defaults derived
# from `${prefix}` would point into the build sandbox, so:
#  - there is no default `.pc` search path: callers set `PKG_CONFIG_PATH` and
#    `PKG_CONFIG_LIBDIR`.  On Windows pkgconf instead searches `lib/pkgconfig`
#    and `share/pkgconfig` next to its own `bin` directory.
#  - there is no default personality search path: personalities (cross
#    configurations selected by `--personality` or a `<triplet>-pkg-config`
#    name) must be given as paths to `.personality` files.
#  - `-L` and `-I` flags for the conventional Unix system directories are
#    dropped from the output, as in distribution builds.  Override them with
#    `PKG_CONFIG_SYSTEM_LIBRARY_PATH` and `PKG_CONFIG_SYSTEM_INCLUDE_PATH`.
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --disable-static \
    --with-pkg-config-dir="" \
    --with-personality-dir="" \
    --with-system-libdir=/usr/lib:/lib \
    --with-system-includedir=/usr/include
make -j${nproc}
make install

# Install `pkgconf` under the name `pkg-config` too, as distributions do
if [[ "${target}" == *-mingw* ]]; then
    cp "${bindir}/pkgconf${exeext}" "${bindir}/pkg-config${exeext}"
else
    ln -s pkgconf "${bindir}/pkg-config"
fi
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("pkgconf", :pkgconf),
    ExecutableProduct("pkg-config", :pkg_config),
    LibraryProduct(["libpkgconf", "libpkgconf-8"], :libpkgconf),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    julia_compat = "1.6",
)
