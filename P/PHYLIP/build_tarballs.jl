# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PHYLIP"
version = v"3.697.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "http://evolution.gs.washington.edu/phylip/download/phylip-$(version.major).$(version.minor).tar.gz",
        "9a26d8b08b8afea7f708509ef41df484003101eaf4beceb5cf7851eb940510c1"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/phylip-*/
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/windows_fixes.patch"

mkdir -p ${bindir} ${libdir}

cd $WORKSPACE/srcdir/phylip-*/src/

if [[ "${bb_target}" == *apple* ]]; then
    make CC="${CC}" -f Makefile.osx install
    mv ../exe/lib* ${libdir}/
    mv ../exe/* ${bindir}/
elif [[ "${bb_target}" == *mingw* ]]; then
    make CC="${CC}" -f Makefile.cyg install
    mv ../source/*.dll ${libdir}/
    mv ../source/* ${bindir}/
else
    make CC="${CC}" -f Makefile.unx install
    mv ../exe/lib* ${libdir}/
    mv ../exe/* ${bindir}/
fi

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
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    #Platform("x86_64", "macos"; ),
    #Platform("x86_64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct(["libdrawtree", "drawtree"], :libdrawtree),
    LibraryProduct(["libdrawgram", "drawgram"], :libdrawgram),
    ExecutableProduct("dnacomp", :dnacomp),
    ExecutableProduct("drawgram", :drawgram),
    ExecutableProduct("gendist", :gendist),
    ExecutableProduct("treedist", :treedist),
    ExecutableProduct("dnapenny", :dnapenny),
    ExecutableProduct("neighbor", :neighbor),
    ExecutableProduct("promlk", :promlk),
    ExecutableProduct("dnaml", :dnaml),
    ExecutableProduct("drawtree", :drawtree),
    ExecutableProduct("protpars", :protpars),
    ExecutableProduct("clique", :clique),
    ExecutableProduct("fitch", :fitch),
    ExecutableProduct("mix", :mix),
    ExecutableProduct("move", :move),
    ExecutableProduct("dnadist", :dnadist),
    ExecutableProduct("restml", :restml),
    ExecutableProduct("dnapars", :dnapars),
    ExecutableProduct("dnamlk", :dnamlk),
    ExecutableProduct("restdist", :restdist),
    ExecutableProduct("dolmove", :dolmove),
    ExecutableProduct("contml", :contml),
    ExecutableProduct("protdist", :protdist),
    ExecutableProduct("dnainvar", :dnainvar),
    ExecutableProduct("pars", :pars),
    ExecutableProduct("retree", :retree),
    ExecutableProduct("seqboot", :seqboot),
    ExecutableProduct("contrast", :contrast),
    ExecutableProduct("dollop", :dollop),
    ExecutableProduct("dolpenny", :dolpenny),
    ExecutableProduct("consense", :consense),
    ExecutableProduct("dnamove", :dnamove),
    ExecutableProduct("factor", :factor),
    ExecutableProduct("kitsch", :kitsch),
    ExecutableProduct("penny", :penny),
    ExecutableProduct("proml", :proml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
