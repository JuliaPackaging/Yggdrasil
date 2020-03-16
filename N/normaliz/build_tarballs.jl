# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "normaliz"
version = v"3.8.4"

# Collection of sources required to build normaliz
sources = [
    ArchiveSource("https://github.com/Normaliz/Normaliz/releases/download/v$version/normaliz-$version.tar.gz",
    "80d21ebaf1a2d472ccdc1e1b2e42b4d71f45f3b8df4d7195ff83edf38f8945c8")
]

# Bash recipe for building across all platforms
script = raw"""
cd normaliz-*
# avoid libtool problems
rm /workspace/destdir/lib/libgmpxx.la
# workaround for #624: remove too old libstdc++ from CompilerSupportLibraries
rm -f /workspace/destdir/lib/libstdc++*
./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --with-gmp=$prefix CPPFLAGS=-I$prefix/include LDFLAGS=-L$prefix/lib
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# windows build would require MPIR instead of GMP for 'long long'
platforms = filter(x->!isa(x,Windows),supported_platforms())
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libnormaliz", :libnormaliz),
    ExecutableProduct("normaliz", :normaliz)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
