# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "WCPG"
version = v"0.9.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/fixif/WCPG/archive/refs/tags/0.9.tar.gz", "4f6b1d2abc298891ae9e3966428c2d8b4e8bbc3528e917d261d8613dea41ab7d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
ln -s ${libdir}/libopenblas.${dlext} ${libdir}/libblas.${dlext}
ln -s ${libdir}/libopenblas.${dlext} ${libdir}/liblapack.${dlext}
cd $WORKSPACE/destdir/include/
wget https://www.netlib.org/clapack/f2c.h
cd $WORKSPACE/srcdir/WCPG-0.9/
chmod +x autogen.sh 
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
exit
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
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
    Dependency(PackageSpec(name="MPFI_jll", uuid="e8b5fb6c-218f-5c08-bc3d-6b0e551bbffd"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
