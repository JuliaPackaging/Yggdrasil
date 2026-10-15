using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(@__DIR__, "..", "common.jl"))

name = "PETSc"
version = petsc_version

sources = petsc_sources()

script = petsc_script(cpu_preamble, raw"""build_petsc double real    Int64 opt
build_petsc double real    Int64 deb     # compile at least one debug version
build_petsc double complex Int64 opt
build_petsc single real    Int64 opt
build_petsc single complex Int64 opt
build_petsc double real    Int32 opt
build_petsc double complex Int32 opt
build_petsc single real    Int32 opt
build_petsc single complex Int32 opt""")

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# We attempt to build for all defined platforms
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# PETSc uses C++ internally, in particular `std::to_string`.
# (This is only used for debugging, and it would be straightforward to
# replace this by calls to `malloc`, `realloc`, and `snprintf`.)
platforms = expand_cxxstring_abis(platforms)

filter!(p -> nbits(p) != 32, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    ExecutableProduct("ex4", :ex4),
    ExecutableProduct("ex42", :ex42),
    ExecutableProduct("ex19", :ex19),
    ExecutableProduct("ex19_int32", :ex19_int32),
    ExecutableProduct("ex19_int64_deb", :ex19_int64_deb),

    # dont_dlopen: the Int64 and Int32 variants link external packages with identical symbol
    # names but different integer ABIs, so consumers dlopen only the variant they use.
    #
    # Default build, equivalent to Float64_Real_Int64
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc, "\$libdir/petsc/double_real_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc_Float64_Real_Int64, "\$libdir/petsc/double_real_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_real_Int64_deb", :libpetsc_Float64_Real_Int64_deb, "\$libdir/petsc/double_real_Int64_deb/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_complex_Int64", :libpetsc_Float64_Complex_Int64, "\$libdir/petsc/double_complex_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_single_real_Int64", :libpetsc_Float32_Real_Int64, "\$libdir/petsc/single_real_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_single_complex_Int64", :libpetsc_Float32_Complex_Int64, "\$libdir/petsc/single_complex_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_real_Int32", :libpetsc_Float64_Real_Int32, "\$libdir/petsc/double_real_Int32/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_complex_Int32", :libpetsc_Float64_Complex_Int32, "\$libdir/petsc/double_complex_Int32/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_single_real_Int32", :libpetsc_Float32_Real_Int32, "\$libdir/petsc/single_real_Int32/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_single_complex_Int32", :libpetsc_Float32_Complex_Int32, "\$libdir/petsc/single_complex_Int32/lib"; dont_dlopen=true),
]

dependencies = petsc_dependencies(platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs.
# NOTE: llvm16 seems to have an issue with PETSc 3.18.x as on apple architectures it doesn't know how to create dynamic libraries
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.12", preferred_gcc_version=v"9")
