using BinaryBuilder, Pkg

name = "Heptagon"
version = v"1.05.00"

sources = [
    DirectorySource("./bundled"),

    GitSource("https://github.com/ocaml/stdlib-shims",
              "fb6815e5d745f07fd567c11671149de6ef2e74c8"),  # 0.3.0
    GitSource("https://github.com/backtracking/ocamlgraph",
              "710007690fb2286f9f2ce10e19fa47a67b634670"),  # 2.2.0
    #GitSource("https://github.com/garrigue/lablgtk",       # needed for simulator (disabled for now, due to Gtk2 dependency)
    #          "e38c8478493b76ab906ec916c24f8f38a67b0702"), # 2.18.14
    GitSource("https://gitlab.inria.fr/fpottier/menhir",
              "d71051f500c4f34c9faf93192a593cdf4903b0c0"),  # 20240715

    GitSource("https://gitlab.inria.fr/synchrone/heptagon",
              "af93d1f0916b7ff37cb88beb8744ecb976d53ae0")
]

script = raw"""
apk add ncurses # needed for tput

# XXX: define this variable upstream?
host=$MACHTYPE
host_full=$(ls /opt/bin | grep $host)


# dependency: stdlib-shims

cd ${WORKSPACE}/srcdir/stdlib-shims
dune build -j ${nproc}
dune install --libdir=$OCAMLLIB


# dependency: ocamlgraph

cd ${WORKSPACE}/srcdir/ocamlgraph
dune build -p ocamlgraph -j ${nproc}
dune install ocamlgraph --libdir=$OCAMLLIB

# also build it for the host, as we'll need it to build heptagon for the host
(
    export OCAMLLIB=/opt/$host/lib/ocaml PATH=/opt/bin/$host_full:/opt/$host/bin:$PATH
    dune build -p ocamlgraph -j ${nproc}
    dune install ocamlgraph --libdir=$OCAMLLIB --prefix=$host_prefix
)


# dependency: menhir

cd ${WORKSPACE}/srcdir/menhir

# generate the menhir binary for the host
(
    export OCAMLLIB=/opt/$host/lib/ocaml PATH=/opt/bin/$host_full:/opt/$host/bin:$PATH
    dune build -j ${nproc}
    dune install --libdir=$OCAMLLIB --prefix=$host_prefix
)
rm -rf _build

# make menhir use bytecode binaries so that the multi-stage build works by interpretation
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/menhir-compile-bytecode.patch

# compile the menhir library for the target
dune build -j ${nproc} -p menhirLib
dune install --libdir=$OCAMLLIB -p menhirLib


# heptagon

cd ${WORKSPACE}/srcdir/heptagon
install_license COPYING

# get rid of the camlp4 dependency, which is hard to cross-compile
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/heptagon-remove-camlp4-reatk.patch
autoconf

# first, generate a host compiler we can execute here
(
    export OCAMLLIB=/opt/$host/lib/ocaml PATH=/opt/bin/$host_full:/opt/$host/bin:$PATH
    ./configure --prefix=$prefix --libdir=$OCAMLLIB
    make -C compiler native
)
cp compiler/heptc.native /tmp
make clean

# XXX: get rid of the host stdlibs, because they get accidentally picked up...
#      Error: Files "utilities/misc.cmx"
#             and "/opt/x86_64-linux-musl/lib/ocaml/str/str.cmxa"
#             make inconsistent assumptions over interface "Str"
rm -rf /opt/$host/lib/ocaml
ln -s /opt/$target/lib/ocaml /opt/$host/lib/ocaml

# then, configure the build for the target
./configure --prefix=$prefix --libdir=$prefix/lib/ocaml --enable-native
make || true

# the build fails because it cannot execute the target compiler to generate the stdlib.
# swap in the previously built host compiler and build the standard library
cp /tmp/heptc.native compiler/heptc.native
make -C lib

# finally, re-build the compiler for the target so that we can distribute it
rm compiler/heptc.native
make -C compiler native

make install
if [[ ${target} == *mingw* ]]; then
    mv $prefix/bin/heptc $prefix/bin/heptc.exe
fi
"""

platforms = filter(supported_platforms()) do p
    if nbits(p) == 32
        # OCaml 5+ only supports 64-bit
        return false
    end
    if Sys.isfreebsd(p)
        # Our OCaml shards don't support FreeBSD
        return false
    end
    if arch(p) == "x86_64" && libc(p) == "musl"
        # This recipe only supports cross-compilation, so exclude x86_64-linux-musl
        return false
    end
    return true
end

products = [
    ExecutableProduct("heptc", :heptc),
    # ExecutableProduct("hepts", :hepts), # disabled for now (due to Gtk2 dependency)
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               compilers=[:c, :ocaml], julia_compat="1.6", preferred_ocaml_version=v"5.3")
