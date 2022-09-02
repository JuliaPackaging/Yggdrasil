# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Exodus"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gsjaardema/seacas.git", "a1da779b061fbdc750f18bcae29295dc5064cb74")
    # GitSource("https://github.com/gsjaardema/seacas.git", "2f865eba1d377177509fe95794710691afd5e9e3")
]

# Bash recipe for building across all platforms
script = raw"""
# install TPLs first
#
cd $WORKSPACE/srcdir/seacas && ACCESS=`pwd`
./install-tpl.sh

# build exodus
#
mkdir build
cd build
### The SEACAS code will install in ${INSTALL_PATH}/bin, ${INSTALL_PATH}/lib, and ${INSTALL_PATH}/include.
INSTALL_PATH=${prefix} \
FORTRAN=NO \
NETCDF_PATH=${prefix} \
PNETCDF_PATH=${prefix} \
HDF5_PATH=${prefix} \
../cmake-exodus

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libnetcdf", :libnetcdf),
    # LibraryProduct("libhdf5", :libhdf5)
    LibraryProduct("libexodus", :libexodus)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("HDF5_jll")
    # Dependency("NetCDF_jll"),
    # Dependency("HDF5_jll")
    # Dependency("MbedTLS_jll", compat="2.28.0"),
    # Dependency("LibCURL_jll", compat="7.73.0"),
    # Dependency("NetCDF_jll", compat="400.702.402"),
    # Dependency("HDF5_jll", compat="1.12.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8")
