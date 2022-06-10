# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GibbsSeaWater"
version = v"3.5.1"

# Collection of sources required to build GibbsSeaWater
# note 3.05.0-4 is too old to be cross-compiled on FreeBSD
sources = [
    ArchiveSource(
        "https://github.com/TEOS-10/GSW-C/archive/d392e91cb63341f543ed1609c4eff613055ab3cb.zip", "454c46ec00468aeba048fa4f3cee095f927925ab699b1d1b3a25a838cef2d22c"),
]



# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == aarch64-apple-* ]]; then
    # Linking libomp requires the function `__divdc3`, which is implemented in
    # `libclang_rt.osx.a` from LLVM compiler-rt.
    LDFLAGS="-L${libdir}/darwin -lclang_rt.osx"
fi
cd $WORKSPACE/srcdir/GSW-C-*
cc -fPIC -c -O3 -Wall gsw_oceanographic_toolbox.c gsw_saar.c
cc $LDFLAGS -fPIC -shared -o libgswteos.$dlext gsw_oceanographic_toolbox.o gsw_saar.o -lm
mkdir -p ${libdir}
cp libgswteos.$dlext ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgswteos", :libgswteos)
]

llvm_version = v"13.0.1"
# Dependencies that must be installed before this package can be built
dependencies = [
    # We need libclang_rt.osx.a, because this library provides the
    # implementation of `__divdc3`.
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version); platforms=[Platform("aarch64", "macos")]),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_llvm_version=llvm_version)
