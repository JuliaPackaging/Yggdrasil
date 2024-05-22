using BinaryBuilder, Pkg

# This is a subproject of zstd that lives in the zstd repository but, like the other
# subprojects, is not built by default. It also has no Makefile or other build system
# of its own, so here it's built manually. The version is set to the version of zstd
# even though this subproject doesn't necessarily change between zstd versions, simply
# for convenience.
name = "ZstdSeekable"
version = v"1.5.6"

sources = [
    ArchiveSource("https://github.com/facebook/zstd/releases/download/v$version/zstd-$version.tar.gz",
                  "8c29e06cf42aacc1eafc4077ae2ec6c6fcb96a626157e0593d5e82a34fd403c1"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/zstd-*/contrib/seekable_format/
${CC} -O3 -g -fPIC zstdseek_compress.c zstdseek_decompress.c -shared -o libzstd_seekable.${dlext} -lzstd -I${includedir} -I../../lib/common/ -L${libdir}
install -Dvm 644 zstd_seekable.h "${includedir}/zstd_seekable.h"  # might as well I guess?
install -Dvm 755 libzstd_seekable.${dlext} "${libdir}/libzstd_seekable.${dlext}"
install_license ../../LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzstd_seekable", :libzstd_seekable),
]

dependencies = [
    Dependency(PackageSpec(; name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4");
               compat="^$version"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
