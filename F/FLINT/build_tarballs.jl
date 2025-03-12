# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Moreover, all our packages using this JLL use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, we can increment the minor version
# e.g. go from 200.600.300 to 200.601.300.
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 2.7.0 to 200.690.000.
#
# There is currently no plan to change the major version, except when upstream itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.
#

# WARNING WARNING WARNING: any change to the the version of this JLL should be carefully
# coordinated with corresponding changes to Singular_jll.jl, Nemo.jl and polymake_jll.jl
# and possibly other packages.
name = "FLINT"
upstream_version = v"3.2.0"
version_offset = v"0.0.0"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build FLINT
sources = [
   ArchiveSource("https://github.com/flintlib/flint/releases/download/v$(upstream_version)/flint-$(upstream_version).tar.gz",
                 "6d182c4a05d3d6bfc611565d6331d02f94066a3be32df36ed880264afa9c30f4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flint*
if [[ ${target} == *musl* ]]; then
   # because of some ordering issue with pthread.h and sched.h includes
   export CFLAGS=-D_GNU_SOURCE
elif [[ ${target} == *mingw* ]]; then
   extraflags=--enable-reentrant
fi

./bootstrap.sh
./configure --host=${target} --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix --with-blas=$prefix ${extraflags}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Currently skipped due to the following error: `configure: error: Could not find mpfr.h`
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libflint", :libflint)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
    Dependency("MPFR_jll", v"4.1.1"),
    Dependency("OpenBLAS32_jll", v"0.3.28"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version=v"6",
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
