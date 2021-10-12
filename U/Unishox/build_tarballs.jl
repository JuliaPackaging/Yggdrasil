using BinaryBuilder

name = "Unishox"
version = v"1.0.0"
sources = [
    ArchiveSource("https://github.com/siara-cc/Unishox/archive/refs/tags/1.0.0.tar.gz", "7349d5a68501eed8a13eb45dac19c3c846877037fd56ee721b305ac506721f86"),
]


script = raw"""
cd $WORKSPACE/srcdir/Unishox-1.0.0
mkdir -p "${libdir}"
gcc -o ${libdir}/libunishox.${dlext} unishox2.c -shared -std=gnu11 -fPIC -Werror -Wall -Wcast-align -Wpointer-arith -Wformat-security -Wmissing-format-attribute -W -Wno-error=format-nonliteral 

"""


platforms = supported_platforms(;experimental=true)

products = [
    LibraryProduct("libunishox", :libunishox),
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")
