# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoftHSM2"
version = v"2.6.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dist.opendnssec.org/source/softhsm-$(version).tar.gz", "61249473054bcd1811519ef9a989a880a7bdcc36d317c9c25457fc614df475f2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/softhsm-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libsofthsm2", :libsofthsm2, "lib/softhsm"),
    ExecutableProduct("softhsm2-keyconv", :softhsm2_keyconv),
    ExecutableProduct("softhsm2-util", :softhhsm2_util),
    ExecutableProduct("softhsm2-dump-file", :softhsm2_dump_file)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
