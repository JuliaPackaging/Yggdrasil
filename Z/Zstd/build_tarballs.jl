using BinaryBuilder

name = "Zstd"
version = v"1.4.5"

sources = [
    ArchiveSource("https://github.com/facebook/zstd/releases/download/v$version/zstd-$version.tar.gz",
                  "98e91c7c6bf162bf90e4e70fdbc41a8188b9fa8de5ad840c401198014406ce9e"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/zstd-*/
mkdir build-zstd && cd build-zstd
if [[ "${target}" == i686-linux-musl ]]; then
    # We can't run executables for i686-linux-musl in the BB environment
    sed -i "s/needs_exe_wrapper = false/needs_exe_wrapper = true/" "${MESON_TARGET_TOOLCHAIN}"
elif [[ "${target}" == aarch64-linux-gnu ]]; then
    # Work around https://github.com/facebook/zstd/issues/1872
    #
    #   ../programs/util.c:76:29: error: ‘stat_t’ has no member named ‘st_mtim’
    #            timebuf[1] = statbuf->st_mtim;
    #                                ^
    sed -i "s/c_args = \[\]/c_args = ['-D_POSIX_C_SOURCE']/" "${MESON_TARGET_TOOLCHAIN}"
fi
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" ../build/meson/
ninja -j${nproc}
ninja install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzstd", :libzstd),
    ExecutableProduct("zstd", :zstd),
    ExecutableProduct("zstdmt", :zstdmt),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
