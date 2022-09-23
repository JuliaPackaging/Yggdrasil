# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "StarPU"
version = v"1.3.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://files.inria.fr/starpu/starpu-$(version)/starpu-$(version).tar.gz", "73adf2a5d25b04023132cfb1a8d9293b356354af7d1134e876122a205128d241"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd starpu*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/fortify.patch"
mkdir build
cd build
../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-fortran --disable-build-doc --disable-build-examples
make -j${nproc}
make install
install_license ../COPYING.LGPL
rm -r $prefix/share/doc/starpu
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(filter!(p -> p ≠ Platform("aarch64", "linux", libc="musl"), supported_platforms()))


# The products that we will ensure are always built
products = [
    LibraryProduct(["libstarpu-1.3", "libstarpu-1"], :libstarpu),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9.1.0")
