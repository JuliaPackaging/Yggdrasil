# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PHYLIP"
version = v"3.697.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://evolution.gs.washington.edu/phylip/download/phylip-3.697.tar.gz", "9a26d8b08b8afea7f708509ef41df484003101eaf4beceb5cf7851eb940510c1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd phylip-3.697/src/
make -f Makefile.unx install
mv ../exe/* $prefix/
install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libdrawtree", :libdrawtree_so),
    LibraryProduct("libdrawgram", :libdrawgram_so),
    ExecutableProduct("dnacomp", :dnacomp),
    ExecutableProduct("drawgram", :drawgram),
    ExecutableProduct("gendist", :gendist),
    ExecutableProduct("retree", :retree),
    ExecutableProduct("dnapenny", :dnapenny),
    ExecutableProduct("mix", :mix),
    ExecutableProduct("penny", :penny),
    ExecutableProduct("dnaml", :dnaml),
    ExecutableProduct("drawtree", :drawtree),
    ExecutableProduct("promlk", :promlk),
    ExecutableProduct("clique", :clique),
    ExecutableProduct("fitch", :fitch),
    ExecutableProduct("dnadist", :dnadist),
    ExecutableProduct("protpars", :protpars),
    ExecutableProduct("dnapars", :dnapars),
    ExecutableProduct("seqboot", :seqboot),
    ExecutableProduct("treedist", :treedist),
    ExecutableProduct("dnamlk", :dnamlk),
    ExecutableProduct("protdist", :protdist),
    ExecutableProduct("dolmove", :dolmove),
    ExecutableProduct("contml", :contml),
    ExecutableProduct("proml", :proml),
    ExecutableProduct("dnainvar", :dnainvar),
    ExecutableProduct("move", :move),
    ExecutableProduct("restdist", :restdist),
    ExecutableProduct("restml", :restml),
    ExecutableProduct("contrast", :contrast),
    ExecutableProduct("dollop", :dollop),
    ExecutableProduct("dolpenny", :dolpenny),
    ExecutableProduct("consense", :consense),
    ExecutableProduct("dnamove", :dnamove),
    ExecutableProduct("factor", :factor),
    ExecutableProduct("kitsch", :kitsch),
    ExecutableProduct("neighbor", :neighbor),
    ExecutableProduct("pars", :pars)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
