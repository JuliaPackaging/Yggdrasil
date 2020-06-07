# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "normaliz"
version = v"3.8.5"

# Collection of sources required to build normaliz
sources = [
    ArchiveSource("https://github.com/Normaliz/Normaliz/releases/download/v$version/normaliz-$version.tar.gz",
                  "cf4fdaaa6ffcd8d268b1f16dd4b64cf86f1eab55177e611f8ef672e7365435a0")
]

# Bash recipe for building across all platforms
script = raw"""
cd normaliz-*
# avoid libtool problems
rm "${prefix}/lib/libgmpxx.la"
./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --with-gmp=$prefix CPPFLAGS=-I$prefix/include LDFLAGS=-L${libdir}
make -j${nproc}
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
