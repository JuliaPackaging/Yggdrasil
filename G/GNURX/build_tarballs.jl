using BinaryBuilder

name = "GNURX"
version = v"2.5.1"

sources = [
    ArchiveSource("https://download.sourceforge.net/mingw/Other/UserContributed/regex/mingw-regex-$(version)/mingw-libgnurx-$(version)-src.tar.gz",
                  "7147b7f806ec3d007843b38e19f42a5b7c65894a57ffc297a76b0dcd5f675d76"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/mingw-libgnurx-*

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared
make -j${nproc}
make install

install_license COPYING.LIB
"""

platforms = supported_platforms(; exclude=!Sys.iswindows)

products = [
    LibraryProduct(["libgnurx", "libgnurx-0"], :libgnurx),
    FileProduct("include/regex.h", :regex_h),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
