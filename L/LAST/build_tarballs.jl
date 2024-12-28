# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "LAST"
version = v"1499"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://gitlab.com/mcfrith/last.git",
        "2cc68d3ba8ae5ca46ceeb69302aef18b9db04f46",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/last
install_license COPYING.txt
export CXXFLAGS=" -O3 -Wall -g -std=c++11 -pthread"
if [[ "${target}" != aarch64-* ]]; then
    CXXFLAGS="${CXXFLAGS} -msse4"
fi
make CXXFLAGS="${CXXFLAGS}" -j${nproc}
make bindir=${bindir} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# NOTE: Windows builds require Cygwin (sys/mman dependency)
platforms = filter(
    p -> !Sys.iswindows(p) && !(arch(p) in ("powerpc64le", "armv6l", "armv7l")),
    supported_platforms(),
)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
# NOTE: last-dotplot not supported due to Python Dependency
products = Product[
    ExecutableProduct("lastal", :lastal),
    ExecutableProduct("lastal5", :lastal5),
    ExecutableProduct("lastdb", :lastdb),
    ExecutableProduct("lastdb5", :lastdb5),
    ExecutableProduct("last-map-probs", :last_map_probs),
    ExecutableProduct("last-merge-batches", :last_merge_batches),
    ExecutableProduct("last-pair-probs", :last_pair_probs),
    ExecutableProduct("last-postmask", :last_postmask),
    ExecutableProduct("last-split", :last_split),
    ExecutableProduct("last-split5", :last_split5),
    ExecutableProduct("last-train", :last_train),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(; name = "Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a");
        compat = "1.2.12",
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
    preferred_gcc_version = v"6",
)

