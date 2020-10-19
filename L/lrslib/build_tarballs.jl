# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lrslib"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaPolyhedra/lrslib.git",
              "d8b723a2c315614979a8354f9e768d273d14a215"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lrslib*
extraargs=""
cflags="-O3 -Wall"

# 32bit linux, arm and windows:
if [[ $target == i686* ]] || [[ $target == arm* ]]; then
  # no 128 bit ... patch makefile
  atomic_patch -p1 ../patches/no128bit.patch
fi

if [[ $target == *apple* ]]; then
  sed -i -e 's#-Wl,-soname=#-install_name #' makefile
  extraargs="SONAME=liblrs.0.dylib SHLINK=liblrs.dylib SHLIB=liblrs.0.0.0.dylib"
elif [[ $target == *freebsd* ]]; then
  export CC="$CC $LDFLAGS"
elif [[ $target == *mingw* ]]; then
  extraargs="SONAME=liblrs-0.dll SHLINK=liblrs.dll SHLIB=liblrs-0-0-0.dll"
  cflags="$cflags -DSIGNALS -DTIMES"
fi

make prefix=$prefix INCLUDEDIR=$prefix/include LIBDIR=${libdir} CFLAGS="$cflags" $extraargs -j ${nproc} install
if [[ $target == *mingw* ]]; then
  # rename binaries and move libraries
  for file in ${bindir}/{lrs,lrsnash,redund}; do mv $file $file.exe; done
  mv ${prefix}/lib/*lrs*.dll ${libdir}/
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("lrs", :lrs)
    ExecutableProduct("lrsnash", :lrsnash)
    ExecutableProduct("redund", :redund)
    LibraryProduct("liblrs", :liblrs)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

