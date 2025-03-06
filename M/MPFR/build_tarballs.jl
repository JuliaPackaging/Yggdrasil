# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using BinaryBuilderBase: sanitize
using Pkg

name = "MPFR"
version = v"4.2.1"

# Collection of sources required to build MPFR
sources = [
    ArchiveSource("https://www.mpfr.org/mpfr-$(version)/mpfr-$(version).tar.xz",
                  "277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

cd $WORKSPACE/srcdir/mpfr-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared --disable-static --with-gmp=${prefix} --enable-thread-safe --enable-shared-cache --disable-float128 --disable-decimal-float
make -j${nproc}
make install

# On Windows, make sure non-versioned filename exists...
if [[ ${target} == *mingw* ]]; then
    cp -v ${libdir}/libmpfr-*.dll ${libdir}/libmpfr.dll
fi
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpfr", :libmpfr),
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll",
                                uuid="4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version=llvm_version);
                    platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5", preferred_llvm_version=llvm_version,
               julia_compat="1.6")

# Build trigger: 1
