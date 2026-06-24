using BinaryBuilder, Pkg

name = "OCamlbuild"
version = v"0.15.0"

sources = [
    GitSource("https://github.com/ocaml/ocamlbuild.git",
              "af319408376aae66dffcf7d31c6926aef19f4f84"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ocamlbuild*
make configure PREFIX=$prefix OCAML_NATIVE=true
make -j ${nproc}
make install
install_license LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]

products = [
    ExecutableProduct("ocamlbuild", :ocamlbuild),
]

dependencies = [
    BuildDependency(PackageSpec("OCaml_jll", v"5.3.0")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"6", julia_compat="1.6")

