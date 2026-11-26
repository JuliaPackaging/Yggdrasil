using BinaryBuilder2

name = "XML2"
version = v"2.15.4"

sources = [
    ArchiveSource("https://download.gnome.org/sources/libxml2/$(version.major).$(version.minor)/libxml2-$(version).tar.xz",
                  "98087fd181d9070724f3fbc65c7377db03038eb92bd882374daff44940138821"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libxml2-*

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --without-python \
    --disable-static \
    --with-zlib=${prefix} \
    --with-iconv=${prefix}
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libxml2", :libxml2),
    ExecutableProduct("xmlcatalog", :xmlcatalog),
    ExecutableProduct("xmllint", :xmllint),
]

# The first versions built by BinaryBuilder2, whose audit can't resolve the
# libraries of JLLs built by BinaryBuilder 1
target_dependencies = [
    JLLSource("Zlib_jll"; version=v"1.4.1"),
    JLLSource("Libiconv_jll"; version=v"1.18.1"),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    target_dependencies,
    julia_compat = "1.6",
)
