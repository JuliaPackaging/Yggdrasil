# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BiqCrunch"
version = v"2.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.inria.fr/mbesanco/BiqCrunch/-/archive/v$(version)/BiqCrunch-v$(version).tar.gz",
                  "45f2f5f16bda636658aac40da0d1d18b9fbdc8d22bab29f9adfe2c9467a413db")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd BiqCrunch-*/src/
make -f Makefile.BinaryBuilder 
"""

# BiqCrunch only supports Unix x86_64 or aarch64
platforms = filter(p -> Sys.isunix(p) && (arch(p) == "x86_64" || arch(p) == "aarch64"), supported_platforms())
platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("max-indep-set_bq", :maxindepset_bq),
    ExecutableProduct("k-cluster_bq", :kcluster_bq),
    ExecutableProduct("max-cut_bq", :maxcut_bq),
    ExecutableProduct("generic_bq", :generic_bq)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
