# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

include("../common.jl")

name = "MPFR"
version = v"4.2.2"

sources = mpfr_sources(version)
script = mpfr_script()
platforms = mpfr_platforms()
products = mpfr_products()

preferred_llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = mpfr_dependencies(platforms; llvm_compilerrt_version=preferred_llvm_version)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5", preferred_llvm_version=preferred_llvm_version,
               julia_compat="1.6")
