using BinaryBuilder, Pkg

name = "Heptagon"
version = v"1.05.00"

sources = [
    DirectorySource("./bundled"),

    ArchiveSource("http://download.camlcity.org/download/findlib-1.9.6.tar.gz",
                  "2df996279ae16b606db5ff5879f93dbfade0898db9f1a3e82f7f845faa2930a2"),
    FileSource("https://github.com/backtracking/ocamlgraph/releases/download/2.1.0/ocamlgraph-2.1.0.tbz",
               "0f962c36f9253df2393955af41b074b6a426b2f92a9def795b2005b57d302d65"),
    GitSource("https://github.com/ocaml/camlp-streams.git",
              "567fa15f32192a6a7cd12e6c9e804fec43460126"),
    GitSource("https://github.com/camlp4/camlp4.git",
              "47e8a7c1082ce4e3004794931fd48259a364a5e4"),
    # GitSource("https://github.com/garrigue/lablgtk.git", # needed for simulator (disabled for now, due to Gtk2 dependency)
    #           "e38c8478493b76ab906ec916c24f8f38a67b0702"),
    ArchiveSource("https://gitlab.inria.fr/fpottier/menhir/-/archive/20240715/archive.tar.gz",
                  "ef488644aaaacbfaada7ebf08d499d64ce31e15494297c3dc8f58725fc9ac030"),
    FileSource("https://github.com/ocaml/stdlib-shims/releases/download/0.3.0/stdlib-shims-0.3.0.tbz",
               "babf72d3917b86f707885f0c5528e36c63fccb698f4b46cf2bab5c7ccdd6d84a"),
    GitSource("https://gitlab.inria.fr/synchrone/heptagon.git",
              "af93d1f0916b7ff37cb88beb8744ecb976d53ae0")
]

script = raw"""
apk add ncurses # needed for tput

cd ${WORKSPACE}/srcdir/findlib*
prefix="" ./configure -no-topfind
prefix="" make -j ${nproc}
prefix="" make install

tar -C ${WORKSPACE}/srcdir/ -xf ${WORKSPACE}/srcdir/stdlib-shims*.tbz && rm ${WORKSPACE}/srcdir/stdlib-shims*.tbz
cd ${WORKSPACE}/srcdir/stdlib-shims*
dune build -j ${nproc}
dune install --prefix $prefix --libdir=$prefix/lib/ocaml/

tar -C ${WORKSPACE}/srcdir/ -xf ${WORKSPACE}/srcdir/ocamlgraph*.tbz && rm ${WORKSPACE}/srcdir/ocamlgraph*.tbz
cd ${WORKSPACE}/srcdir/ocamlgraph*
dune build -p ocamlgraph -j ${nproc} @install
dune install ocamlgraph --prefix $prefix --libdir=$prefix/lib/ocaml/

cd ${WORKSPACE}/srcdir/camlp-streams
dune build -j ${nproc}
dune install --prefix=$prefix --libdir=$prefix/lib/ocaml/

cd ${WORKSPACE}/srcdir/camlp4*
./configure --libdir=$prefix/lib/ocaml
make -j ${nproc}
make install install-META

cd ${WORKSPACE}/srcdir/menhir*
dune build -j ${nproc}
dune install --prefix=$prefix --libdir=$prefix/lib/ocaml/

cd ${WORKSPACE}/srcdir/heptagon
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
./configure --prefix=${prefix} --libdir=$prefix/lib/ocaml/ --enable-native
make # (-j${nproc} not supported by lib/Makefile)
make install
install_license COPYING
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]

products = [
    ExecutableProduct("heptc", :heptc),
    # ExecutableProduct("hepts", :hepts), # disabled for now (due to Gtk2 dependency)
]

dependencies = [
    BuildDependency(PackageSpec("OCaml_jll", v"5.3.0")),
    BuildDependency("Dune_jll"),
    BuildDependency("OCamlbuild_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"6", julia_compat="1.6")
