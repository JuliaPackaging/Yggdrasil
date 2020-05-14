# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Julia does not allow identifiers starting with a digit, so we can't
# call this just "4ti2"
name = "lib4ti2"
version = v"1.6.9"

# Collection of sources required to build 4ti2
sources = [
    ArchiveSource("https://github.com/4ti2/4ti2/releases/download/Release_$(version.major)_$(version.minor)_$(version.patch)/4ti2-$(version).tar.gz",
                  "3053e7467b5585ad852f6a56e78e28352653943e7249ad5e5174d4744d174966"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/4ti2-*

# Remove misleading libtool files 
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
rm -f /opt/${MACHTYPE}/${MACHTYPE}/lib*/*.la

# Patch #1 for fixing cross-compilation: The correctness of the patch
# relies on us using clang or GCC (in a new enough version) as compiler;
# otherwise we ought to turn off ftrapv support to be on the safe side.
atomic_patch -p1 ../patches/ftrapv.patch

# Patch #2 for fixing cross-compilation: The code detecting presence and
# usability of GMP is broken for cross compilation; fix that
atomic_patch -p1 ../patches/gmp.patch

# Patch to fix compilation on mingw32: add missing #include <time.h>
atomic_patch -p1 ../patches/time.patch


./configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=$target \
    --with-gcc-arch=pentium4 \
    --with-gmp=${prefix} \
    --with-glpk=${prefix} \
    --enable-shared \
    --disable-static
make -j${nproc}
make install

rm -rf ${WORKSPACE}/destdir/${target}

# On Windows, make sure non-versioned filename exists...
if [[ ${target} == *mingw* ]]; then
    cp -v ${prefix}/bin/lib4ti2common-*.dll ${prefix}/bin/lib4ti2common.dll
    cp -v ${prefix}/bin/lib4ti2gmp-*.dll ${prefix}/bin/lib4ti2gmp.dll
    cp -v ${prefix}/bin/lib4ti2int32-*.dll ${prefix}/bin/lib4ti2int32.dll
    cp -v ${prefix}/bin/lib4ti2int64-*.dll ${prefix}/bin/lib4ti2int64.dll
    cp -v ${prefix}/bin/lib4ti2util-*.dll ${prefix}/bin/lib4ti2util.dll
    cp -v ${prefix}/bin/libzsolve-*.dll ${prefix}/bin/libzsolve.dll
fi
"""

# Build for all platforms
platforms = supported_platforms()

# 4ti2 contains std::string values; to avoid incompatibilities across
# the GCC 4/5 version boundary, we need the following:
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
   LibraryProduct("lib4ti2gmp", :lib4ti2),
   LibraryProduct("lib4ti2int32", :lib4ti2int32),
   LibraryProduct("lib4ti2int64", :lib4ti2int64),
   LibraryProduct("libzsolve", :libzsolve),

   # The commented out executables below are shell scripts, and are not
   # handled on Windows currently, which is why they are commented out
   # for now.
   # Also, Julia identifiers can't start with a digit, so we have to add
   # a prefix to the symbol used to refer to some of the executables.
   ExecutableProduct("4ti2gmp", :exe4ti2gmp),
   ExecutableProduct("4ti2int32", :exe4ti2int32),
   ExecutableProduct("4ti2int64", :exe4ti2int64),
   #ExecutableProduct("circuits", :circuits),
   ExecutableProduct("genmodel", :genmodel),
   ExecutableProduct("gensymm", :gensymm),
   #ExecutableProduct("graver", :graver),
   #ExecutableProduct("groebner", :groebner),
   #ExecutableProduct("hilbert", :hilbert),
   #ExecutableProduct("markov", :markov),
   #ExecutableProduct("minimize", :minimize),
   #ExecutableProduct("normalform", :normalform),
   ExecutableProduct("output", :output),
   ExecutableProduct("ppi", :ppi),
   #ExecutableProduct("qsolve", :qsolve),
   #ExecutableProduct("rays", :rays),
   #ExecutableProduct("walk", :walk),
   #ExecutableProduct("zbasis", :zbasis),
   ExecutableProduct("zsolve", :zsolve),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"),
    Dependency("GLPK_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
