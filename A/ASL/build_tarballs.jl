# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ASL"
version = v"0.1.2"

# Collection of sources required to build ThinASLBuilder
sources = [
    ArchiveSource("http://netlib.org/ampl/solvers.tgz",
                  "65bb7dc72ce072bd4fa49578164a8430c03b458969cd4abe5ff6d8e9c09ad2dc"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/solvers/
head -17 asl.h > LICENSE.txt
mkdir -p ${includedir}
mkdir -p ${libdir}

all_load="--whole-archive"
noall_load="--no-whole-archive"
makefile="makefile.u"
cflags=""

if [[ -f $WORKSPACE/srcdir/asl-extra/arith.h.$target ]]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.$target ./arith.h
fi

if [[ "${target}" == "arm-linux-musleabihf" ]]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.arm-linux-gnueabihf ./arith.h
elif [[ $target == "i686-linux-musl" ]]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.i686-linux-gnu ./arith.h
elif [[ "${target}" == "aarch64-linux-musl" ]]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.aarch64-linux-gnu ./arith.h
elif [[ "${target}" == *-freebsd* ]]; then
    cp $WORKSPACE/srcdir/asl-extra/arith.h.x86_64-linux-gnu ./arith.h
    cflags="-D__XSI_VISIBLE=1"
elif [[ "${target}" == *-mingw* ]]; then
    makefile="$WORKSPACE/srcdir/asl-extra/makefile.mingw"
elif [[ "${target}" == *-apple-* ]]; then
    all_load="-all_load"
    noall_load="-noall_load"
fi

make -f $makefile CC="$CC" CFLAGS="-O -fPIC $cflags"
c++ -fPIC -shared -I$WORKSPACE/srcdir/asl-extra -I. $WORKSPACE/srcdir/asl-extra/aslinterface.cc -Wl,${all_load} amplsolver.a -Wl,${noall_load} -o libasl.${dlext}
cp libasl.${dlext} ${libdir}
cp *.h ${includedir}
cp *.hd ${includedir}
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libasl", :libasl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
