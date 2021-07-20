# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "WCPG"
version = v"0.9.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/fixif/WCPG/archive/refs/tags/0.9.tar.gz", "4f6b1d2abc298891ae9e3966428c2d8b4e8bbc3528e917d261d8613dea41ab7d"),
    FileSource("https://www.netlib.org/clapack/f2c.h", "7d323c009951dbd40201124b9302cb21daab2d98bed3d4a56b51b48958bc76ef"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
ln -s ${libdir}/libopenblas.${dlext} ${libdir}/libblas.${dlext}
ln -s ${libdir}/libopenblas.${dlext} ${libdir}/liblapack.${dlext}
mv $WORKSPACE/srcdir/f2c.h $WORKSPACE/destdir/include/
cd $WORKSPACE/srcdir/WCPG-0.9/
chmod +x autogen.sh 
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("x86_64", "macos"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libwcpg", :libwcpg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.1.2")
    Dependency("MPFR_jll")
    Dependency("MPFI_jll")
    Dependency("OpenBLAS32_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
