# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Collection of sources required to build the source code
# Here GitSource does not allow for some clone arguments to be passed. E.g. we cannot pass
# --recursive
#
# CODE using the mpq_rational from boost
sources = [
        GitSource("https://github.com/MathieuDutSik/polyhedral_common", "c7f3c4072b7583c17f8151f8d0f953694dc5864a"),
]
name = "polyhedral"
version = v"0.3" # third version pf the code

# Bash recipe for building across all platforms
script = raw"""
cd polyhedral_common
git submodule update --init --recursive
cd src_export_oscar
export GMP_INCDIR=$includedir
export GMP_CXX_LINK="-L$libdir -lgmpxx -lgmp"

export BOOST_INCDIR=$includedir
export BOOST_LINK="-L$libdir -lboost_serialization"

export EIGEN_PATH=$includedir/eigen3

export NAUTY_INCLUDE="-I$includedir/nauty"
export NAUTY_LINK="-L$libdir -lnauty"

export GLPK_LINK="-L$libdir -lglpk"

make -j${nproc}

cp CP_TestCompletePositivity $bindir
cp CP_TestCopositivity $bindir
cp GRP_ListMat_Vdiag_EXT_Automorphism $bindir
cp GRP_ListMat_Vdiag_EXT_Isomorphism $bindir
cp GRP_ListMat_Vdiag_EXT_Invariant $bindir
cp POLY_dual_description_group $bindir
cp POLY_cdd_LinearProgramming $bindir
cp POLY_sampling_facets $bindir
cp POLY_redundancy_Equivariant $bindir
cp LATT_Automorphism $bindir
cp LATT_Isomorphism $bindir
cp LATT_canonicalize $bindir
cp LATT_near $bindir
cp LATT_IndefiniteReduction $bindir
cp SHORT_TestRealizability $bindir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# This is needed to avoid some errors GCC4 vs GCC5 at compilation.
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("CP_TestCompletePositivity", :CP_TestCompletePositivity)
    ExecutableProduct("CP_TestCopositivity", :CP_TestCopositivity)
    ExecutableProduct("GRP_ListMat_Vdiag_EXT_Automorphism", :GRP_ListMat_Vdiag_EXT_Automorphism)
    ExecutableProduct("GRP_ListMat_Vdiag_EXT_Isomorphism", :GRP_ListMat_Vdiag_EXT_Isomorphism)
    ExecutableProduct("GRP_ListMat_Vdiag_EXT_Invariant", :GRP_ListMat_Vdiag_EXT_Invariant)
    ExecutableProduct("POLY_redundancy_Equivariant", :POLY_redundancy_Equivariant)
    ExecutableProduct("POLY_dual_description_group", :POLY_dual_description_group)
    ExecutableProduct("POLY_sampling_facets", :POLY_sampling_facets)
    ExecutableProduct("POLY_cdd_LinearProgramming", :POLY_cdd_LinearProgramming)
    ExecutableProduct("LATT_near", :LATT_near)
    ExecutableProduct("LATT_Automorphism", :LATT_Automorphism)
    ExecutableProduct("LATT_Isomorphism", :LATT_Isomorphism)
    ExecutableProduct("LATT_canonicalize", :LATT_canonicalize)
    ExecutableProduct("LATT_IndefiniteReduction", :LATT_IndefiniteReduction)
    ExecutableProduct("SHORT_TestRealizability", :SHORT_TestRealizability)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
    BuildDependency("Eigen_jll"),
    Dependency("GLPK_jll"),
    Dependency("nauty_jll"; compat = "~2.6.13"),
    Dependency("boost_jll", compat = "=1.76.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
