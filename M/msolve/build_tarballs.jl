# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "msolve"
upstream_version = v"0.7.3"

version_offset = v"0.0.1"
version = VersionNumber(upstream_version.major*100+version_offset.major,
                        upstream_version.minor*100+version_offset.minor,
                        upstream_version.patch*100+version_offset.patch)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/algebraic-solving/msolve.git", "42b9e3364c797554e4e132ca46c4cf22ff54a932")
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
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)   # not POSIX
# At the moment we cannot add optimized versions for specific architectures
# since the logic of artifact selection when loading the package is not
# working well.
# platforms = expand_microarchitectures(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmsolve", :libmsolve),
    LibraryProduct("libneogb", :libneogb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("FLINT_jll", compat = "~300.100.301"),
    Dependency("MPFR_jll", v"4.1.1"),

    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  julia_compat="1.6", preferred_gcc_version = v"6")
