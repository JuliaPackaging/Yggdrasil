using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

# espresso
name = "Espresso"
version = v"1.0.0"
upstream_version = "2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/classabbyamp/espresso-logic.git",
              "85265139e9598852f9388d293658a1977a829a01")
]

script = raw"""
cd ${WORKSPACE}/srcdir/espresso-logic/espresso-src
make -j${nproc} CC=${CC}
install -Dvm 755 ../bin/espresso ${bindir}/espresso${exeext}
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# core-math uses unsigned __int128 which is unavailable on 32-bit platforms
platforms = supported_platforms(exclude= x -> (
    Sys.iswindows(x) ||
    Sys.isfreebsd(x) ||
    nbits(x) == 32
))
# platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("espresso", :espresso),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script,
    platforms, products, dependencies;
    julia_compat="1.6",
)

