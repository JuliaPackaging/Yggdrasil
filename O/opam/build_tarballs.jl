using BinaryBuilder, Pkg

name = "opam"
version = v"2.3.0"

sources = [
    GitSource("https://github.com/ocaml/opam.git", "e13109411952d4f723a165c2a24b8c03c4945041")
]

script = raw"""
cd $WORKSPACE/srcdir/opam
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
