# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Collection of sources required to build the source code
# Here GitSource does not allow for some clone arguments to be passed. E.g. we cannot pass
# --recursive
#
# CODE using the mpq_rational from boost
sources = [
        GitSource("https://github.com/MathieuDutSik/polyhedral_common", "ed8cbe285fec0ac24ccd6a1e9d3371e9b14a3927"),
]
name = "polyhedral"
version = v"0.1" # <-- This is the first version of it but this is rather arbitrary

# Bash recipe for building across all platforms
script = raw"""
cd polyhedral_common
git submodule update --init --recursive
cd src_export_oscar
export GMP_INCDIR=$WORKSPACE/destdir/include
export GMP_C_LINK="-L$WORKSPACE/destdir/lib -lgmp"

export BOOST_INCDIR=$WORKSPACE/destdir/include
export BOOST_LINK="-L$WORKSPACE/destdir/lib -lboost_serialization"

export EIGEN_PATH=$WORKSPACE/destdir/include/eigen3

export NAUTY_INCLUDE="-I$WORKSPACE/destdir/include/nauty"
export NAUTY_LINK="-L$WORKSPACE/destdir/lib -lnauty"

make

cp GRP_ListMat_Subset_EXT_Automorphism $WORKSPACE/destdir/bin
cp GRP_ListMat_Subset_EXT_Isomorphism $WORKSPACE/destdir/bin
cp GRP_ListMat_Subset_EXT_Invariant $WORKSPACE/destdir/bin
cp IndefiniteReduction $WORKSPACE/destdir/bin
cp POLY_cdd_lp2 $WORKSPACE/destdir/bin
cp POLY_dual_description_group $WORKSPACE/destdir/bin
cp POLY_sampling_facets $WORKSPACE/destdir/bin
cp sv_exact $WORKSPACE/destdir/bin
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# This is needed to avoid some errors GCC4 vs GCC5 at compilation.
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("GRP_ListMat_Subset_EXT_Automorphism", :GRP_ListMat_Subset_EXT_Automorphism)
    ExecutableProduct("GRP_ListMat_Subset_EXT_Isomorphism", :GRP_ListMat_Subset_EXT_Isomorphism)
    ExecutableProduct("GRP_ListMat_Subset_EXT_Invariant", :GRP_ListMat_Subset_EXT_Invariant)
    ExecutableProduct("IndefiniteReduction", :IndefiniteReduction)
    ExecutableProduct("POLY_cdd_lp2", :POLY_cdd_lp2)
    ExecutableProduct("POLY_dual_description_group", :POLY_dual_description_group)
    ExecutableProduct("POLY_sampling_facets", :POLY_sampling_facets)
    ExecutableProduct("sv_exact", :sv_exact)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
    Dependency("Eigen_jll"),
    Dependency("nauty_jll"; compat = "~2.6.13"),
    Dependency("boost_jll", compat = "=1.76.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"12")

