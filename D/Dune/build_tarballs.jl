using BinaryBuilder, Pkg

name = "Dune"
version = v"3.17.1"

sources = [
    FileSource("https://github.com/ocaml/dune/releases/download/$(version)/dune-$(version).tbz",
               "6b9ee5ed051379a69ca45173ac6c5deb56b44a1c16e30b7c371343303d835ac6"),
]

script = raw"""
tar -C ${WORKSPACE}/srcdir/ -xf ${WORKSPACE}/srcdir/dune*.tbz && rm ${WORKSPACE}/srcdir/dune-*.tbz
cd ${WORKSPACE}/srcdir/dune*
ocaml boot/bootstrap.ml -j ${nproc}
./_boot/dune.exe build -p dune --profile dune-bootstrap
./_boot/dune.exe install dune --prefix $prefix
install_license LICENSE.md
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]

products = [
    ExecutableProduct("dune", :dune),
]

dependencies = [
    BuildDependency(PackageSpec("OCaml_jll", v"5.3.0")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"6", julia_compat="1.6")
