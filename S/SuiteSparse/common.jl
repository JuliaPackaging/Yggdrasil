using BinaryBuilder

make_name(; suitesparse32=false) = "SuiteSparse" * (suitesparse32 ? "32" : "")
version = v"5.4.0"

# Collection of sources required to build SuiteSparse
sources = [
    ArchiveSource("https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v$(version).tar.gz",
                  "d9d62d539410d66550d0b795503a556830831f50087723cb191a030525eda770"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

# Bash recipe for building across all platforms
function make_script(; suitesparse32=false)
    script = """
    SUITESPARSE32=$suitesparse32
    """

    return script * raw"""
    cd $WORKSPACE/srcdir/SuiteSparse-*

    # Apply Jameson's shlib patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/01-SuiteSparse-shlib.patch

    # Disable OpenMP as it will probably interfere with blas threads and Julia threads
    FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

    if [[ ${target} == *mingw32* ]]; then
      FLAGS+=(UNAME=Windows)
      FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir} -shared")
    else
      FLAGS+=(UNAME="$(uname)")
      FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir}")
    fi

    if [[ "$SUITESPARSE32" == false && "${nbits}" == 64 && "${target}" != aarch64-* ]]; then
        SUN="-DSUN64 -DLONGBLAS='long long'"
        FLAGS+=(BLAS="-lopenblas64_" LAPACK="-lopenblas64_")
    else
        FLAGS+=(BLAS="-lopenblas" LAPACK="-lopenblas")
    fi

    # Disable METIS in CHOLMOD by passing -DNPARTITION and avoiding linking metis
    # FLAGS+=(MY_METIS_LIB="-lmetis" MY_METIS_INC="${prefix}/include")
    FLAGS+=(UMFPACK_CONFIG="$SUN" CHOLMOD_CONFIG+="$SUN -DNPARTITION" SPQR_CONFIG="$SUN")

    # Add a suffix to 64-bit shared libraries
    if [[ "$SUITESPARSE32" == false ]]; then
      atomic_patch -p1 ${WORKSPACE}/srcdir/patches/02-library-suffix.patch
      SUFFIX=64_
      FLAGS+=(LIBRARY_SUFFIX="$SUFFIX")
      # NOTE: symbols.txt should be updated for new versions of SuiteSparse
      # Ideally, CFLAGS would be a list, and we'd add it to FLAGS,
      # but I can't figure out how to get the Bash right.
      export CFLAGS=""
      for s in $(grep -v "#" ${WORKSPACE}/srcdir/symbols.txt); do
        CFLAGS="$CFLAGS-D$s=$s$SUFFIX "
      done
    fi

    make -j${nproc} -C SuiteSparse_config "${FLAGS[@]}" library config

    makefiles="$(find . -name Makefile* -o -name *.mk)"
    for proj in SuiteSparse_config AMD BTF CAMD CCOLAMD COLAMD CHOLMOD LDL KLU UMFPACK RBio SPQR; do
      if [[ "$SUITESPARSE32" == false ]]; then
        link="-l$(echo $proj | tr [:upper:] [:lower:] | tr -d _)"
        sed -i "s/$link/$link$SUFFIX/g" $makefiles
      fi
      make -j${nproc} -C $proj "${FLAGS[@]}" library CFOPENMP="$CFOPENMP"
      make -j${nproc} -C $proj "${FLAGS[@]}" install CFOPENMP="$CFOPENMP"
    done

    # For now, we'll have to adjust the name of the OpenBLAS library on macOS and FreeBSD.
    # Eventually, this should be fixed upstream
    if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *freebsd* ]]; then
      echo "-- Modifying library name for OpenBLAS"
      BLAS=libopenblas
      if [[ "$SUITESPARSE32" == false ]]; then
        BLAS+=64_
      fi
      for nm in libcholmod libspqr libumfpack; do
          # Figure out what version it probably latched on to:
          if [[ "${target}" == *-apple-* ]]; then
              OPENBLAS_LINK=$(otool -L ${libdir}/${nm}${SUFFIX}.dylib | grep "$BLAS" | awk '{ print $1 }')
              install_name_tool -change "${OPENBLAS_LINK}" "@rpath/$BLAS.dylib" "${libdir}/${nm}${SUFFIX}.dylib"
          elif [[ "${target}" == *freebsd* ]]; then
              OPENBLAS_LINK=$(readelf -d ${libdir}/${nm}${SUFFIX}.so | grep "$BLAS" | sed -e 's/.*\[\(.*\)\].*/\1/')
              patchelf --replace-needed "${OPENBLAS_LINK}" "$BLAS.so" "${libdir}/${nm}${SUFFIX}.so"
          fi
      done
    fi

    # Delete the extra soversion libraries built. https://github.com/JuliaPackaging/Yggdrasil/issues/7
    if [[ "${target}" == *-mingw* ]]; then
        rm -f ${libdir}/lib*.*.${dlext}
        rm -f ${libdir}/lib*.*.*.${dlext}
    fi

    install_license LICENSE.txt

    # Compile SuiteSparse_wrapper shim
    cd $WORKSPACE/srcdir/SuiteSparse_wrapper
    "${CC}" ${CFLAGS} -O2 -shared -fPIC -I${prefix}/include SuiteSparse_wrapper.c -o ${libdir}/libsuitesparse_wrapper$SUFFIX.${dlext} -L${libdir} "-lcholmod$SUFFIX"
    """
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
function make_products(; suitesparse32=false)
    products = [
        :libsuitesparseconfig, :libamd, :libbtf, :libcamd, :libccolamd, :libcolamd, :libcholmod,
        :libldl, :libklu, :libumfpack, :librbio, :libspqr, :libsuitesparse_wrapper,
    ]
    suffix = suitesparse32 ? "" : "64_"
    return map(lib -> LibraryProduct("$lib$suffix", lib), products)
end

# Dependencies that must be installed before this package can be built
function make_dependencies(; suitesparse32=false)
    blas = suitesparse32 ? "OpenBLAS32_jll" : "OpenBLAS_jll"
    return [
        Dependency(blas),
        # Dependency("METIS_jll"),
    ]
end

# Build the tarballs
function build(; suitesparse32=false)
    name = make_name(; suitesparse32=suitesparse32)
    script = make_script(; suitesparse32=suitesparse32)
    products = make_products(; suitesparse32=suitesparse32)
    dependencies = make_dependencies(; suitesparse32=suitesparse32)
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
end
