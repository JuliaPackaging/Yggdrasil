# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "msolve"
version = v"0.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.lip6.fr/safey/msolve.git", "0c05f5f49a28e1cc0b649702b7e0934f63a1bea0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/msolve/
./autogen.sh

ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes ./configure --with-gnu-ld --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
filter!(!Sys.iswindows, platforms)  # no FLINT_jll available

# The products that we will ensure are always built
products = [
    LibraryProduct("libmsolve", :libmsolve),
    LibraryProduct("libneogb", :libneogb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("FLINT_jll", compat = "~200.900.000"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")
