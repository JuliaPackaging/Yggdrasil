# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OCaml"
version = v"4.10.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ocaml/ocaml/archive/4.10.0.tar.gz", "58bae0f0a79daf86ec755a173e593fef4ef588f15c6185993af88ceb9722bc39")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ocaml-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libcamlrun_shared", :libcamlrun_shared),
    LibraryProduct("dllunix", :dllunix),
    ExecutableProduct("ocamlcmt", :ocamlcmt),
    LibraryProduct("bigarray", :bigarray),
    ExecutableProduct("ocamlprof.opt", :ocamlprof),
    ExecutableProduct("ocamlmklib.opt", :ocamlmklib),
    ExecutableProduct("ocamlobjinfo.opt", :ocamlobjinfo),
    FileProduct("lib/ocaml/compiler-libs/main.o", :main),
    ExecutableProduct("ocamlopt.opt", :ocamlopt),
    FileProduct("lib/ocaml/compiler-libs/optmain.o", :optmain),
    LibraryProduct("dllthreads", :dllthreads),
    ExecutableProduct("objinfo_helper", :objinfo_helper, "lib/ocaml"),
    LibraryProduct("libasmrun_shared", :libasmrun_shared),
    ExecutableProduct("ocamlmktop.opt", :ocamlmktop),
    FileProduct("lib/ocaml/std_exit.o", :std_exit),
    ExecutableProduct("ocamllex.opt", :ocamllex),
    LibraryProduct("unix", :unix),
    ExecutableProduct("ocamldep.opt", :ocamldep),
    ExecutableProduct("ocamlcp.opt", :ocamlcp),
    ExecutableProduct("ocamldoc.opt", :ocamldoc),
    FileProduct("lib/ocaml/profiling.o", :profiling),
    LibraryProduct("str", :str),
    ExecutableProduct("ocamlrund", :ocamlrund),
    ExecutableProduct("ocamlruni", :ocamlruni),
    LibraryProduct("dllcamlstr", :dllcamlstr),
    ExecutableProduct("ocamlyacc", :ocamlyacc),
    ExecutableProduct("ocamlrun", :ocamlrun),
    ExecutableProduct("ocamlc.opt", :ocamlc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
