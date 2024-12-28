using BinaryBuilder
using Pkg
using BinaryBuilderBase: sanitize

name = "LibUV"
version = v"2"

# Collection of sources required to build libuv
sources = [
    GitSource("https://github.com/JuliaLang/libuv.git",
              "af4172ec713ee986ba1a989b9e33993a07c60c9e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libuv/

# Touch some files so that the build system doesn't attempt to re-run `autoconf`:
touch -c aclocal.m4
touch -c Makefile.in
touch -c configure

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

# `--with-pic` isn't enough; we really really need -fPIC and -DPIC everywhere...
# everywhere, especially on FreeBSD. In the end, isn't FreeBSD all that matters?
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic CFLAGS="${CFLAGS} -DPIC -fPIC" CXXFLAGS="${CXXFLAGS} -DPIC -fPIC"
make -j${nproc} V=1
make install
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libuv", :libuv),
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version); platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

# Note: we explicitly lie about this because we don't have the new
# versioning APIs worked out in BB yet.
version = v"2.0.1"
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # We need GCC 4.9+ for stdatomic.h
               julia_compat="1.6", preferred_gcc_version=v"5", preferred_llvm_version=llvm_version)

# Build trigger: 1
