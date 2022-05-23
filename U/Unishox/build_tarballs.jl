using BinaryBuilder

name = "Unishox"
version = v"1.0.2"
sources = [
    ArchiveSource("https://github.com/siara-cc/Unishox2/archive/refs/tags/$(version).tar.gz", "24391d16d4f84f239bb97eb704d80231221a9a58743a87ae1ca7eed27cf7e9bb"),
]


script = raw"""
cd $WORKSPACE/srcdir/Unishox*
mkdir -p "${libdir}"
cc -o ${libdir}/libunishox.${dlext} unishox2.c -shared -std=gnu11 -fPIC -Werror -Wall -Wcast-align -Wpointer-arith -Wformat-security -Wmissing-format-attribute -W -Wno-error=format-nonliteral 
"""


platforms = supported_platforms()

products = [
    LibraryProduct("libunishox", :libunishox),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")
