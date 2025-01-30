using BinaryBuilder, Pkg

name = "opam"
version = v"2.3.0"

sources = [
    ArchiveSource("https://github.com/ocaml/opam/releases/download/2.3.0/opam-full-2.3.0.tar.gz",
                  "506ba76865dc315b67df9aa89e7abd5c1a897a7f0a92d7b2694974fdc532b346")
]

script = raw"""
cd $WORKSPACE/srcdir/opam-full-2.3.0
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-vendored-deps
make -j
make install
install_license LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl")
]

products = [
    ExecutableProduct("opam", :opam),
]

dependencies = [
    BuildDependency(PackageSpec(name="OCaml_jll", version=v"5.3.0"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"6", julia_compat="1.6")
