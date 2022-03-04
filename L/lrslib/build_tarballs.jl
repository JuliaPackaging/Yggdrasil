# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lrslib"
version = v"0.3.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://cgm.cs.mcgill.ca/~avis/C/lrslib/archive/lrslib-071b.tar.gz",
                  "df22682cd742315fe04f866cfe4804d5950f7dc7f514d5b5f36f5b7f5aff9188"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lrslib*
extraargs=""
cflags="-fPIC -O3 -Wall -DLRS_QUIET"

# 32bit linux, arm and windows:
if [[ $target == i686* ]] || [[ $target == arm* ]]; then
  # no 128 bit support needs extra flags
  extraargs="BITS=-DB32 MPLRSOBJ2= SHLIBOBJ2= "
fi

if [[ $target == *apple* ]]; then
  export CC=gcc
  sed -i -e 's#-Wl,-soname=#-install_name #' makefile
  extraargs="SONAME=liblrs.0.dylib SHLINK=liblrs.dylib SHLIB=liblrs.0.0.0.dylib ${extraargs}"
elif [[ $target == *freebsd* ]]; then
  export CC="gcc"
elif [[ $target == *mingw* ]]; then
  extraargs="SONAME=liblrs-0.dll SHLINK=liblrs.dll SHLIB=liblrs-0-0-0.dll ${extraargs}"
  cflags="$cflags -DSIGNALS -DTIMES"
fi

make prefix=${prefix} \
     INCLUDEDIR=${includedir} \
     LIBDIR=${libdir} \
     CFLAGS="${cflags}" \
     ${extraargs} \
     -j ${nproc} \
   install

if [[ $target == *mingw* ]]; then
  # rename binaries and move libraries
  for file in ${bindir}/{lrs,lrsnash}; do mv $file $file.exe; done
  mv ${prefix}/lib/*lrs*.dll ${libdir}/
fi

${CC} -shared ${cflags} -o "${libdir}/liblrsnash.${dlext}" lrsnashlib.c -L${libdir} -llrs -lgmp -Wl,-rpath,${libdir} -DMA -DGMP -DLRS_QUIET -I${includedir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("lrs", :lrs)
    ExecutableProduct("lrsnash", :lrsnash)
    LibraryProduct("liblrs", :liblrs)
    LibraryProduct("liblrsnash", :liblrsnash)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
