# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
include("../common.jl")

version = v"1.3.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/BenLangmead/bowtie.git",
        "c347414708bfc5ec9fd5ed8a9c5a9bd10b311a6d",
    ),
]

# Bash recipe for building across all platforms
# TODO: Windows build cannot handle missing sys headers
script = raw"""
cd ${WORKSPACE}/srcdir/bowtie
install_license LICENSE
make -j${nproc}
make install prefix=${prefix} bindir=${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# NOTE: Bowtie cannot be built on 32-bit platforms
# TODO: Fix missing cpuid headers for certain platforms
platforms = supported_platforms(;
    exclude = p ->
        arch(p) in ["i686", "armv6l", "armv7l", "powerpc64le"] || Sys.iswindows(p),
)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("bowtie", :bowtie),
    ExecutableProduct("bowtie-align-l", :bowtie_align_l),
    ExecutableProduct("bowtie-align-s", :bowtie_align_s),
    ExecutableProduct("bowtie-build", :bowtie_build),
    ExecutableProduct("bowtie-build-l", :bowtie_build_l),
    ExecutableProduct("bowtie-build-l", :bowtie_build_l),
    ExecutableProduct("bowtie-build-s", :bowtie_build_s),
    ExecutableProduct("bowtie-inspect", :bowtie_inspect),
    ExecutableProduct("bowtie-inspect-l", :bowtie_inspect_l),
    ExecutableProduct("bowtie-inspect-s", :bowtie_inspect_s),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[Dependency(
    PackageSpec(; name = "Zlib_jll", uuid = "83775a58-1f1d-513f-b197-d71354ab007a");
    compat = "1.2.13",
    platforms = platforms,
),]

build_bowtie(version, sources, script, platforms, products, dependencies)
