# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nuSQuIDS"
version = v"1.13.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jsalvado/SQuIDS.git",
              "cd0ccd164b2fe34a59908e8d8aa370464105b107"),  # v1.3.1
    GitSource("https://github.com/arguelles/nuSQuIDS.git",
              "104914da5a25cb0d1548d19dd9f3161c693ce153"),  # v1.13.3
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Set up compiler environment for cross-compilation
export CC=${CC:-cc}
export CXX=${CXX:-c++}
export AR=${AR:-ar}
export LD=${LD:-ld}

# First build SQuIDS
cd SQuIDS
mkdir -p lib

# Configure SQuIDS - pass GSL paths explicitly
./configure --prefix=${prefix} \
    --with-gsl-incdir=${includedir} \
    --with-gsl-libdir=${libdir}

# Build and install
make -j${nproc}
make install

# Now build nuSQuIDS
cd ../nuSQuIDS
mkdir -p lib

# Configure nuSQuIDS - pass all dependency paths explicitly
./configure --prefix=${prefix} \
    --with-squids=${prefix} \
    --with-gsl-incdir=${includedir} \
    --with-gsl-libdir=${libdir} \
    --with-hdf5-incdir=${includedir} \
    --with-hdf5-libdir=${libdir}

# Build and install
make -j${nproc}
make install

# Install data files
mkdir -p ${prefix}/share/nuSQuIDS
cp -r data/* ${prefix}/share/nuSQuIDS/
"""

# Platforms - start with Linux x86_64 and macOS to debug
# Can expand after initial builds work
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

# Expand C++ string ABI (required for C++ libraries)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libSQuIDS", :libSQuIDS),
    LibraryProduct("libnuSQuIDS", :libnuSQuIDS),
    FileProduct("share/nuSQuIDS", :nuSQuIDS_data),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GSL_jll"),
    Dependency("HDF5_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
