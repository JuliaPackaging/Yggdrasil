# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QuEST"
version = v"3.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/QuEST-Kit/QuEST.git", "d4f75f724993b4af8e43a796e3c09ce24ae11670")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd QuEST/
cmake -B build     -DCMAKE_C_STANDARD=99     -DCMAKE_INSTALL_PREFIX=$prefix     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}     -DCMAKE_BUILD_TYPE=Release     .
cmake --build build --parallel ${nproc}
mkdir -p "${includedir}"
cp -vr $WORKSPACE/srcdir/QuEST/QuEST/include/* ${includedir}/
install -Dvm 755 build/QuEST/libQuEST.${dlext} ${libdir}/libQuEST.${dlext}
install_license LICENCE.txt
cd $WORKSPACE/srcdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libQuEST", :libQuEST)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
