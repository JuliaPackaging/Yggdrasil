# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DSDP"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.mcs.anl.gov/hs/software/DSDP/DSDP5.8.zip", "8915e55456f1a7cc5c970ad157d094a5fb399737cf192dfe79b89c2d94d97a8a"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd DSDP*
DSDPROOT="${prefix}"
DSDPLIB="${DSDPROOT}/lib/libdsdp.a"
DSDPLIBSO="${libdir}/libdsdp.${dlext}"

cp include/* ${includedir}
make CC=${CC} SHELL="sh -x" DSDPROOT="${DSDPROOT}" DSDPLIB="${DSDPLIB}" DSDPLIBSO="${DSDPLIBSO}" DSDPCFLAGS="-Wall -fPIC -DPIC" LAPACKBLAS="-L${libdir} -lopenblas" dsdplibrary
make CC=${CC} SHELL="sh -x" DSDPROOT="${DSDPROOT}" DSDPLIB="${DSDPLIB}" DSDPLIBSO="${DSDPLIBSO}" DSDPCFLAGS="-Wall" LAPACKBLAS="-L${libdir} -lopenblas" RM="rm -rf" SH_LD="${CC} ${CFLAGS} -Wall -fPIC -DPIC -shared -L${libdir} -lopenblas" oshared
install_license dsdp-license
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libdsdp", :libdsdp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"6",
)
