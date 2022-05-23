# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LoopTools"
version = v"2.16"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.feynarts.de/looptools/LoopTools-$(version.major).$(version.minor).tar.gz", "D2D07C98F8520C67EABE22973B2F9823D5B636353FFA01DFBCD3A22F65D404B7"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/LoopTools-*
atomic_patch -p1 ../patches/simplify-configure.patch
export AR=ar
export RANLIB=ranlib
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install EXE="${exeext}"
# Now let's build the shared library
cd "${prefix}/lib"
mkdir -p "${libdir}"
gfortran -fPIC -shared $(flagon -Wl,--whole-archive) libooptools.a $(flagon -Wl,--no-whole-archive) -o "${libdir}/libooptools.${dlext}"
rm  libooptools.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libooptools", :libooptools),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
