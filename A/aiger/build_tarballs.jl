# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "aiger"
version = v"1.9.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://fmv.jku.at/aiger/aiger-1.9.9.tar.gz", "1e50d3db36f5dc5ed0e57aa4c448b9bcf82865f01736dde1f32f390b780350c7"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd aiger-1.9.9/
./configure.sh 
make -j
mkdir $prefix/bin
PREFIX=$prefix make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),
    Platform("x86_64", "freebsd")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("aigdd", :aigdd),
    ExecutableProduct("aigreset", :aigreset),
    ExecutableProduct("aigmiter", :aigmiter),
    ExecutableProduct("aignm", :aignm),
    ExecutableProduct("soltostim", :soltostim),
    ExecutableProduct("aigmove", :aigmove),
    ExecutableProduct("aigflip", :aigflip),
    ExecutableProduct("aigunconstraint", :aigunconstraint),
    ExecutableProduct("aigstrip", :aigstrip),
    ExecutableProduct("aigsim", :aigsim),
    ExecutableProduct("aigtodot", :aigtodot),
    ExecutableProduct("aigtoblif", :aigtoblif),
    ExecutableProduct("aigunroll", :aigunroll),
    ExecutableProduct("wrapstim", :wrapstim),
    ExecutableProduct("aigor", :aigor),
    ExecutableProduct("aigtosmv", :aigtosmv),
    ExecutableProduct("aigtocnf", :aigtocnf),
    ExecutableProduct("andtoaig", :andtoaig),
    ExecutableProduct("aigjoin", :aigjoin),
    ExecutableProduct("smvtoaig", :smvtoaig),
    ExecutableProduct("aigfuzz", :aigfuzz),
    ExecutableProduct("aiginfo", :aiginfo),
    ExecutableProduct("bliftoaig", :bliftoaig),
    ExecutableProduct("aigsplit", :aigsplit),
    ExecutableProduct("aigtoaig", :aigtoaig),
    ExecutableProduct("aigand", :aigand)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
