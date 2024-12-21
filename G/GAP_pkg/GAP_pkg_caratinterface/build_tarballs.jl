# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "caratinterface"
upstream_version = "2.3.7" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version
version = offset_version(upstream_version, offset)

# This package only produces an executable and does not need GAP for this at all,
# hence we don't include common.jl

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://www.math.uni-bielefeld.de/~gaehler/gap/CaratInterface/CaratInterface-$(upstream_version).tar.gz",
                  "fdbc0f86befd8bf575c93475b33f58329ce99fe2ef97ba69af1478bc8664059c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd CaratInterface*

tar pzxf carat.tgz
cd carat
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/macos.patch
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp=${prefix}
make -j${nproc}
cd ..

# copy just the executable
mkdir -p ${prefix}/bin/
cp -R carat/bin/* ${prefix}/bin/

install_license GPL
"""

name = gap_pkg_name(name)

platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # we only care about 64bit builds
filter!(!Sys.iswindows, platforms)      # Windows is not supported

dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("Add", :Add),
    ExecutableProduct("Aut_grp", :Aut_grp),
    ExecutableProduct("Bravais_catalog", :Bravais_catalog),
    ExecutableProduct("Bravais_equiv", :Bravais_equiv),
    ExecutableProduct("Bravais_grp", :Bravais_grp),
    ExecutableProduct("Bravais_inclusions", :Bravais_inclusions),
    ExecutableProduct("Bravais_type", :Bravais_type),
    ExecutableProduct("Conj", :Conj),
    ExecutableProduct("Conj_bravais", :Conj_bravais),
    ExecutableProduct("Conjugated", :Conjugated),
    ExecutableProduct("Conv", :Conv),
    ExecutableProduct("Datei", :Datei),
    ExecutableProduct("Elt", :Elt),
    ExecutableProduct("Extensions", :Extensions),
    ExecutableProduct("Extract", :Extract),
    ExecutableProduct("First_perfect", :First_perfect),
    ExecutableProduct("Form_elt", :Form_elt),
    ExecutableProduct("Form_space", :Form_space),
    ExecutableProduct("Formtovec", :Formtovec),
    ExecutableProduct("Full", :Full),
    ExecutableProduct("Gauss", :Gauss),
    ExecutableProduct("Graph", :Graph),
    ExecutableProduct("Idem", :Idem),
    ExecutableProduct("Inv", :Inv),
    ExecutableProduct("Invar_space", :Invar_space),
    ExecutableProduct("Is_finite", :Is_finite),
    ExecutableProduct("Isometry", :Isometry),
    ExecutableProduct("KSubgroups", :KSubgroups),
    ExecutableProduct("KSupergroups", :KSupergroups),
    ExecutableProduct("Kron", :Kron),
    ExecutableProduct("Long_solve", :Long_solve),
    ExecutableProduct("Ltm", :Ltm),
    ExecutableProduct("Mink_red", :Mink_red),
    ExecutableProduct("Minpol", :Minpol),
    ExecutableProduct("Modp", :Modp),
    ExecutableProduct("Mtl", :Mtl),
    ExecutableProduct("Mul", :Mul),
    ExecutableProduct("Name", :Name),
    ExecutableProduct("Normalizer", :Normalizer),
    ExecutableProduct("Normalizer_in_N", :Normalizer_in_N),
    ExecutableProduct("Normlin", :Normlin),
    ExecutableProduct("Orbit", :Orbit),
    ExecutableProduct("Order", :Order_),  # HACK: BinaryBuilderBase doesn't allow using names already in use by Base
    ExecutableProduct("P_lse_solve", :P_lse_solve),
    ExecutableProduct("Pair_red", :Pair_red),
    ExecutableProduct("Pdet", :Pdet),
    ExecutableProduct("Perfect_neighbours", :Perfect_neighbours),
    ExecutableProduct("Polyeder", :Polyeder),
    ExecutableProduct("Presentation", :Presentation),
    ExecutableProduct("Q_catalog", :Q_catalog),
    ExecutableProduct("QtoZ", :QtoZ),
    ExecutableProduct("Red_gen", :Red_gen),
    ExecutableProduct("Rein", :Rein),
    ExecutableProduct("Rest_short", :Rest_short),
    ExecutableProduct("Reverse_name", :Reverse_name),
    ExecutableProduct("Rform", :Rform),
    ExecutableProduct("Same_generators", :Same_generators),
    ExecutableProduct("Scalarmul", :Scalarmul),
    ExecutableProduct("Scpr", :Scpr),
    ExecutableProduct("Short", :Short),
    ExecutableProduct("Short_reduce", :Short_reduce),
    ExecutableProduct("Shortest", :Shortest),
    ExecutableProduct("Signature", :Signature),
    ExecutableProduct("Simplify_mat", :Simplify_mat),
    ExecutableProduct("Standard_affine_form", :Standard_affine_form),
    ExecutableProduct("Sublattices", :Sublattices),
    ExecutableProduct("Symbol", :Symbol_),  # HACK: BinaryBuilderBase doesn't allow using names already in use by Base
    ExecutableProduct("TSubgroups", :TSubgroups),
    ExecutableProduct("TSupergroups", :TSupergroups),
    ExecutableProduct("Torsionfree", :Torsionfree),
    ExecutableProduct("Tr", :Tr),
    ExecutableProduct("Tr_bravais", :Tr_bravais),
    ExecutableProduct("Trace", :Trace),
    ExecutableProduct("Trbifo", :Trbifo),
    ExecutableProduct("Vectoform", :Vectoform),
    ExecutableProduct("Vector_systems", :Vector_systems),
    ExecutableProduct("Vor_vertices", :Vor_vertices),
    ExecutableProduct("ZZprog", :ZZprog),
    ExecutableProduct("Z_equiv", :Z_equiv),
    ExecutableProduct("Zass_main", :Zass_main),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

