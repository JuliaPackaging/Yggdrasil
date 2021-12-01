# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CRlibm"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/JuliaIntervals/CRlibm.jl/raw/368ccdebd57e7a7cc96d47ab6b08e7a597495ff2/deps/src/crlibm-1.0beta4.tar.gz", "6836b4299f9421c99da2bdcd5e04a8d35577db4eb61161a401aa93751a96375d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/crlibm*/

for p in ../patches/*.patch; do
    atomic_patch -p1 "${p}"
done

update_configure_scripts 
export CFLAGS="-fPIC"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -C scs_lib
make -j${nproc} libcrlibm.a
mkdir -p ${libdir}
cc -L. -shared -o ${libdir}/libcrlibm.${dlext} *.o scs_lib/*.o
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcrlibm", :libcrlibm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
