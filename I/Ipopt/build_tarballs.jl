using BinaryBuilder, Pkg

name = "Ipopt"
version = v"3.13.4"

sources = [
    ArchiveSource("https://github.com/coin-or/Ipopt/archive/releases/$(version).tar.gz",
                  "1fdd0f8ea637856d66b1ebdd7d52ad1b8b8c1142d1a4ce0976b200ab280e5683"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Ipopt-releases-*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

LIBASL=(-L${libdir} -lasl)
if [[ "${target}" == *-linux-* ]]; then
  LIBASL+=(-lrt)
fi

./configure --enable-shared \
            --prefix=${prefix} \
            --with-lapack-lflags=-lopenblas \
            --with-mumps-cflags="-I$prefix/include/mumps_seq" \
            --with-mumps-lflags="-L${libdir} -ldmumps -lmpiseq -lmumps_common -lopenblas -lpord" \
            --with-asl-cflags="-I${prefix}/include" \
            --with-asl-lflags="${LIBASL[*]}" \
            --build=${MACHTYPE} \
            --host=${target}

# parallel build fails
make
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libipopt", :libipopt),
    LibraryProduct("libipoptamplinterface", :libipoptamplinterface),
    ExecutableProduct("ipopt", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll"),
    Dependency("OpenBLAS32_jll", v"0.3.9"),  # Ipopt uses 32-bit ints
    Dependency("MUMPS_seq_jll", v"5.2.1", compat="=5.2.1"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
