using BinaryBuilder

name = "IpoptMKL"
version = v"3.13.2"

sources = [
    ArchiveSource("https://github.com/coin-or/Ipopt/archive/releases/$(version).tar.gz",
                  "891ab9e9c7db29fc8ac5c779ccec6313301098de7bbf735ca230cd5544c49496"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Ipopt-releases-*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la

LIBASL=(-L${libdir} -lasl)
if [[ "${target}" == *-linux-* ]]; then
  LIBASL+=(-lrt)
fi

libmkl=(-lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -liomp5 -lpthread -lm -ldl)
if [[ ${target} == *mingw* ]]; then
    libmkl=(${libdir}/mkl_rt.dll ${libdir}/mkl_intel_thread.dll ${libdir}/libiomp5md.dll ${libdir}/libwinpthread-1.dll)
fi

./configure --enable-shared \
            --prefix=${prefix} \
            --with-lapack="${libmkl[*]}" \
            --with-asl-cflags="-I${prefix}/include" \
            --with-asl-lflags="${LIBASL[*]}" \
            --host=${target}

# parallel build fails
make
make install
"""

# disable Windows
# https://stackoverflow.com/questions/16623407/build-error-bad-reloc-address
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    # Platform("i686", "windows"),
    # Platform("x86_64", "windows"),
]
platforms = expand_gfortran_versions(expand_cxxstring_abis(platforms))

# The products that we will ensure are always built
products = [
    LibraryProduct("libipopt", :libipopt),
    ExecutableProduct("ipopt", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll"),
    Dependency("MKL_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
