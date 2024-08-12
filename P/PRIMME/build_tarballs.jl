# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PRIMME"
version = v"3.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/primme/primme.git",
              "8d0ca1812436665564e5fba82d2a485e96fd7627"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ ${nbits} == 64 ]]; then
CFLAGS="-O -fPIC -DNDEBUG -DPRIMME_BLASINT_SIZE=64 -DPRIMME_BLAS_SUFFIX=_64"
else
CFLAGS="-O -fPIC -DNDEBUG -DPRIMME_BLASINT_SIZE=32"
fi

if [[ "${target}" == *mingw* && ${nbits} == 32 ]]; then
  LDFLAGS="-L${libdir} -lopenblas"
elif [[ "${target}" == *mingw* && ${nbits} == 64 ]]; then
  LDFLAGS="-L${libdir} -lopenblas64_"
else
  LDFLAGS="-L${libdir} -lblastrampoline"
fi

cd primme
if [[ "${target}" == *mingw* ]]; then
  sed -i 's/Windows\.h/windows.h/' ./src/linalg/wtime.c
  MDEFS="SLIB=dll"
else
  MDEFS=""
fi

make -j${nproc} CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\" ${MDEFS} solib
make PREFIX=${prefix} ${MDEFS} install

install_license ${WORKSPACE}/srcdir/primme/COPYING.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Compilation on musl fails, apparently because of conflicting use of
# the token I which is a boneheaded macro in complex.h.
platforms = [p for p in supported_platforms() if (get(p.tags, "libc", nothing) != "musl")]

# The products that we will ensure are always built
products = [
    LibraryProduct("libprimme", :libprimme)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363"), platforms=filter(Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]


# Build the tarballs, and possibly a `build.jl` as well.

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8")
