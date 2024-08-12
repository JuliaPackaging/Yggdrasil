# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

name = "KMA"
version = v"1.3.21"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://bitbucket.org/genomicepidemiology/kma.git",
        "2d3acb03ac8f309094eee8d53eb043f033f8d8c0",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/kma
# Apache 2.0 license not included in the bitbucket repo
install_license /usr/share/licenses/APL2
make -j${nproc}
install -Dvm 755 kma${exeext} ${bindir}/kma${exeext}
install -Dvm 755 kma_index${exeext} ${bindir}/kma_index${exeext}
install -Dvm 755 kma_index${exeext} ${bindir}/kma_index${exeext}
install -Dvm 755 kma_shm${exeext} ${bindir}/kma_shm${exeext}
install -Dvm 755 kma_update${exeext} ${bindir}/kma_update${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude = Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("kma", :kma),
    ExecutableProduct("kma_index", :kma_index),
    ExecutableProduct("kma_shm", :kma_shm),
    ExecutableProduct("kma_update", :kma_update),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(; name = "Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a");
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
    preferred_gcc_version = v"8",
)
