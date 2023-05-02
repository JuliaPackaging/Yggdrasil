# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Collection of sources required to build the source code
# Here GitSource does not allow for some clone arguments to be passed. E.g. we cannot pass
# --recursive
#
# CODE using the mpq_rational from boost
sources = [
        GitSource("https://github.com/MathieuDutSik/polyhedral_common", "bfad27e6b80aca0e1c389d1f4b0cdde991bb2ddc"),
]
name = "polyhedral"
version = v"0.2" # <-- This is the first version of it but this is rather arbitrary

# Bash recipe for building across all platforms
script = raw"""
cd polyhedral_common
git submodule update --init --recursive
cd src_export_oscar
export GMP_INCDIR=$includedir
export GMP_C_LINK="-L$libdir -lgmp"

export BOOST_INCDIR=$includedir
export BOOST_LINK="-L$libdir -lboost_serialization"

export EIGEN_PATH=$includedir/eigen3

export NAUTY_INCLUDE="-I$includedir/nauty"
export NAUTY_LINK="-L$libdir -lnauty"

make

cp GRP_LinPolytope_Automorphism $bindir
cp GRP_ListMat_Subset_EXT_Isomorphism $bindir
cp GRP_LinPolytope_Automorphism_GramMat $bindir
cp GRP_LinPolytope_Isomorphism_GramMat $bindir
cp GRP_ListMat_Subset_EXT_Automorphism $bindir
cp GRP_ListMat_Subset_EXT_Invariant $bindir
cp POLY_dual_description_group $bindir
cp POLY_cdd_LinearProgramming $bindir
cp POLY_sampling_facets $bindir
cp LATT_Automorphism $bindir
cp LATT_Isomorphism $bindir
cp IndefiniteReduction $bindir
cp sv_near $bindir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# This is needed to avoid some errors GCC4 vs GCC5 at compilation.
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("GRP_ListMat_Subset_EXT_Automorphism", :GRP_ListMat_Subset_EXT_Automorphism)
    ExecutableProduct("GRP_ListMat_Subset_EXT_Isomorphism", :GRP_ListMat_Subset_EXT_Isomorphism)
    ExecutableProduct("GRP_ListMat_Subset_EXT_Invariant", :GRP_ListMat_Subset_EXT_Invariant)
    ExecutableProduct("IndefiniteReduction", :IndefiniteReduction)
    ExecutableProduct("POLY_dual_description_group", :POLY_dual_description_group)
    ExecutableProduct("POLY_sampling_facets", :POLY_sampling_facets)
    ExecutableProduct("sv_near", :sv_near)
    ExecutableProduct("LATT_Automorphism", :LATT_Automorphism)
    ExecutableProduct("LATT_Isomorphism", :LATT_Isomorphism)
    ExecutableProduct("POLY_cdd_LinearProgramming", :POLY_cdd_LinearProgramming)
    ExecutableProduct("GRP_LinPolytope_Automorphism", :GRP_LinPolytope_Automorphism)
    ExecutableProduct("GRP_LinPolytope_Automorphism_GramMat", :GRP_LinPolytope_Automorphism_GramMat)
    ExecutableProduct("GRP_LinPolytope_Isomorphism_GramMat", :GRP_LinPolytope_Isomorphism_GramMat)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
    BuildDependency("Eigen_jll"),
    Dependency("nauty_jll"; compat = "~2.6.13"),
    Dependency("boost_jll", compat = "=1.76.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
