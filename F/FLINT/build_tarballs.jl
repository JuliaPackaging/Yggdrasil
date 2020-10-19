# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLINT"
version = v"2.6.3"

# Collection of sources required to build FLINT
sources = [
    ArchiveSource("http://www.flintlib.org/flint-$(version).tar.gz",
                  "ce1a750a01fa53715cad934856d4b2ed76f1d1520bac0527ace7d5b53e342ee3")
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

