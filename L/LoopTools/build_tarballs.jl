# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LoopTools"
version = v"2.15"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.feynarts.de/looptools/LoopTools-2.15.tar.gz", "a065ffdc4fe6882aa3bb926134ba8ec875d6c0a633c3d4aa5f70db26542713f2"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/LoopTools-*
atomic_patch -p1 ../patches/simplify-configure.patch
export AR=ar
export RANLIB=ranlib
./configure --prefix=$prefix --host=${target}
make -j${nproc}
make install EXE="${exeext}"
# Now let's build the shared library
cd "${prefix}/lib"
if [[ "${target}" == *-apple-* ]]; then
    whole_archive="-all_load"
    no_whole_archive="-noall_load"
else
    whole_archive="--whole-archive"
    no_whole_archive="--no-whole-archive"
fi
mkdir -p "${libdir}"
gfortran -fPIC -shared -Wl,${whole_archive} libooptools.a -Wl,${no_whole_archive} -o "${libdir}/libooptools.${dlext}"
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
