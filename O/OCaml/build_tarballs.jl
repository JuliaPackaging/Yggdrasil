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
make -j${nproc}
make install
for bin in $(file ${bindir}/* | grep "a ${bindir}/ocamlrun script" | cut -d: -f1); do
    # Fix shebang of ocamlrun scripts to not hardcode
    # a path of the build environment
    sed -i "s?${bindir}/ocamlrun?/usr/bin/env ocamlrun?" "${bin}"
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("ocamlopt.opt", :ocamlopt),
    ExecutableProduct("ocamlc.opt", :ocamlc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
