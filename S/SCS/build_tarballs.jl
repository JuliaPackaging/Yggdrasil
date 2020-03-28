using BinaryBuilder

name = "SCS"
version = v"2.1.1"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "d2c1ae92b8c5c6d45406afd007d1ddad74635cfd")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scs*
flags="DLONG=1 USE_OPENMP=0"
blasldflags="-L${prefix}/lib"
# see https://github.com/JuliaPackaging/Yggdrasil/blob/0bc1abd56fa176e3d2cc2e48e7bf85a26c948c40/OpenBLAS/build_tarballs.jl#L23
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    flags="${flags} BLAS64=1 BLASSUFFIX=_64_"
    blasldflags+=" -lopenblas64_"
else
    blasldflags+=" -lopenblas"
fi

# Patch to reverse this WIN64 change: https://github.com/cvxgrp/scs/commit/9858d6b562f499de75493b85286276c19ad84c6f#diff-a9dbab3214616022c64ee2656440f544
# Looks like it is known that this change causes trouble witn mingw32 (but not for mingw64?):
# https://github.com/cvxgrp/scs/blob/e6ab81db115bb37502de0a9917041a0bc2ded313/.appveyor.yml#L13-L16
cd include
cp glbopts.h glbopts.h.orig
cat > file.patch <<'END'
--- glbopts.h.orig
+++ glbopts.h
@@ -97,7 +97,7 @@
 #ifdef _WIN64
 /* #include <stdint.h> */
 /* typedef int64_t scs_int; */
-typedef long scs_int;
+typedef __int64 scs_int;
 #else
 typedef long scs_int;
 #endif
END
patch -l glbopts.h.orig file.patch -o glbopts.h
cd ..

make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsdir.${dlext}
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsindir.${dlext}

if [[ ${target} == *mingw* ]]; then
    mkdir -p ${prefix}/bin
    cp out/libscs*.dll ${prefix}/bin
else
    mkdir -p ${prefix}/lib
    cp out/libscs*.${dlext} ${prefix}/lib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libscsindir", :indirect),
    LibraryProduct("libscsdir", :direct)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
