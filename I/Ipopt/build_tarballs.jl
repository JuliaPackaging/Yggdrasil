using BinaryBuilder

name = "Ipopt"
version = v"3.13.1"

sources = [
    ArchiveSource("https://github.com/coin-or/Ipopt/archive/releases/$(version).tar.gz",
                  "64fc63a3fe27cf5efaf17ebee861f7db5bf70aacf9c316c0d37e4beb4eb72e11"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Ipopt-releases-3.13.1

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la

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
            --host=${target}

# parallel build fails
make
make install
"""

platforms = expand_gfortran_versions(expand_cxxstring_abis(supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libipopt", :libipopt),
    ExecutableProduct("ipopt", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll"),
    Dependency("OpenBLAS32_jll"),  # Ipopt uses 32-bit ints
    Dependency("MUMPS_seq_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
