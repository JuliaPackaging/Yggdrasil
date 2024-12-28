# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "htscodecs"
version = v"1.5.2"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/samtools/htscodecs.git",
        "2aca18b335bc2b580698e487092b794c514ac62c",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/htscodecs
install_license LICENSE.md
autoreconf -fvi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude = Sys.iswindows)

# The products that we will ensure are always built
products = [LibraryProduct("libhtscodecs", :libhtscodecs)]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(; name = "Bzip2_jll", uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0");
        compat="1.0.8",
    ),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"7",
)

