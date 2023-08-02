# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "bcftools"
version = v"1.14.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/samtools/bcftools.git",
        "5f1bf7a1b016c24d38657bdde5fd2ca27e6954e9",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/bcftools
install_license LICENSE
autoreconf -fvi
export CPPFLAGS="-I${includedir}"
./configure --enable-libgsl --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> libc(p) != "musl", supported_platforms(; exclude = Sys.iswindows))

# The products that we will ensure are always built
products = [ExecutableProduct("bcftools", :bcftools)]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(; name = "htslib_jll", uuid = "f06fe41e-9474-5571-8c61-5634d2b2700c");
        compat = "1.14",
    ),
    Dependency(
        PackageSpec(; name = "GSL_jll", uuid = "1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4");
        compat = "2.7.2",
    ),
    Dependency(
        PackageSpec(; name = "Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a");
        compat = "1.2.13",
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
    preferred_gcc_version = v"4",
)

