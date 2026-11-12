using BinaryBuilder, Pkg

# This is a subproject of zstd that lives in the zstd repository but, like the other
# subprojects, is not built by default. It also has no Makefile or other build system
# of its own, so here it's built manually. The version is set to the version of zstd
# even though this subproject doesn't necessarily change between zstd versions, simply
# for convenience.
name = "ZstdSeekable"
version = v"1.5.7"

sources = [
    ArchiveSource("https://github.com/facebook/zstd/releases/download/v$version/zstd-$version.tar.gz",
                  "eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/zstd-*/contrib/seekable_format/
FLAGS=(-O3 -g -fPIC -shared -DXXH_NAMESPACE="" -L${libdir} -I${includedir} -I. -I../../lib/ -I../../lib/common/ -lzstd -lxxhash)
SOURCES=(zstdseek_compress.c zstdseek_decompress.c)
LIB=libzstd_seekable.${dlext}
${CC} ${SOURCES[@]} -o ${LIB} ${FLAGS[@]}
install -Dvm 644 zstd_seekable.h "${includedir}/zstd_seekable.h"  # might as well I guess?
install -Dvm 755 ${LIB} "${libdir}/${LIB}"
install_license ../../LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzstd_seekable", :libzstd_seekable),
]

dependencies = [
    Dependency(PackageSpec(; name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4");
               compat="^$version"),
    Dependency(PackageSpec(; name="xxHash_jll", uuid="5fdcd639-92d1-5a06-bf6b-28f2061df1a9");
               compat="^0.8.3"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
