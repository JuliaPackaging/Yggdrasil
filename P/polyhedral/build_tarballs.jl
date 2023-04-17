# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Collection of sources required to build the source code
# Here GitSource does not allow for some clone arguments to be passed. E.g. we cannot pass
# --recursive
sources = [
        GitSource("https://github.com/MathieuDutSik/polyhedral_common", "5c03f1f3e0bc10a8d3c36268260895a5981ec663"),
]
name = "POLYHEDRAL"
version = v"0.1" # <-- This is the first version of it but this is rather arbitrary

# Bash recipe for building across all platforms
script = raw"""
git submodule update --init --recursive
cd src_export_oscar
export GMP_INCDIR=$GMP_INCLUDE_DIR
export GMP_CXX_LINK="$GMP_LIBS -lgmpxx -lgmp"

export BOOST_INCDIR=$BOOST_INCLUDE_DIRS
export BOOST_LINK="$BOOST_LIBS -lboost_serialization"

export EIGEN_PATH=$EIGEN_INCLUDE_DIRS

export NAUTY_INCLUDE="-I$NAUTY_INCLUDE_DIR"
export NAUTY_LINK="$prefix/lib/libnauty.a"

make
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("GRP_ListMat_Subset_EXT_Automorphism", :GRP_ListMat_Subset_EXT_Automorphism)
    ExecutableProduct("GRP_ListMat_Subset_EXT_Isomorphism", :GRP_ListMat_Subset_EXT_Isomorphism)
    ExecutableProduct("GRP_ListMat_Subset_EXT_Invariant", :GRP_ListMat_Subset_EXT_Invariant)
    ExecutableProduct("IndefiniteReduction", :IndefiniteReduction)
    ExecutableProduct("POLY_IsomorphismReduction", :POLY_IsomorphismReduction)
    ExecutableProduct("sv_exact", :sv_exact)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("Eigen_jll"),
    Dependency("nauty_jll"; compat = "~2.6.13"),
    Dependency("boost_jll", compat = "=1.76.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")

