# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

name = "nghttp2"
version = v"1.64.0"

# Collection of sources required to build nghttp2
sources = [
    GitSource("https://github.com/nghttp2/nghttp2.git",
              "526ff38e0249acbcc4d0e8958c12cdeae9960cfe"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nghttp2

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

autoreconf -i
automake
autoconf
./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --enable-lib-only
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libnghttp2", :libnghttp2),
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version); platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_llvm_version=llvm_version)

# build trigger: 1
