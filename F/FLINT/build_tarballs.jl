# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

#
# FLINT_jll versions are decoupled from the upstream versions.
# Whenever we package a new official FLINT release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Moreover, all our packages using FLINT_jll use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, we can increment the minor version
# e.g. go from 200.600.300 to 200.601.300.
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 2.7.0 to 200.690.000.
#
# There is currently no plan to change the major version (except when FLINT itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.
#
#
# WARNING WARNING WARNING: any change to the the version of this JLL should be carefully
# coordinated with corresponding changes to Singular_jll.jl, LoadFlint.jl, Nemo.jl,
# and possibly other packages.
name = "FLINT"
version = v"200.690.000"  # WARNING: don't change this

# Collection of sources required to build FLINT
sources = [
    GitSource("https://github.com/wbhart/flint2.git", "60401a410e335f3c243ec069f5c72a2d8365a626"),
#    ArchiveSource("http://www.flintlib.org/flint-$(version).tar.gz",
#                  "ce1a750a01fa53715cad934856d4b2ed76f1d1520bac0527ace7d5b53e342ee3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flint*
if [[ ${target} == *musl* ]]; then
   # because of some ordering issue with pthread.h and sched.h includes
   export CFLAGS=-D_GNU_SOURCE
elif [[ ${target} == *mingw* ]]; then
   extraflags=--reentrant
fi
./configure --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix ${extraflags}
make -j${nproc}
make install LIBDIR=$(basename ${libdir})
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libflint", :libflint)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("MPFR_jll", v"4.0.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               init_block = """
  if !Sys.iswindows() && !(get(ENV, "NEMO_THREADED", "") == "1")
    #to match the global gmp ones
    fm = dlsym(libflint_handle, :__flint_set_memory_functions)
    ccall(fm, Nothing,
      (Ptr{Nothing},Ptr{Nothing},Ptr{Nothing},Ptr{Nothing}),
        cglobal(:jl_malloc),
        cglobal(:jl_calloc),
        cglobal(:jl_realloc),
        cglobal(:jl_free))
  end
""")

