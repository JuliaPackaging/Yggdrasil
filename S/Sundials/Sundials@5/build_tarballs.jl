using BinaryBuilder

name = "Sundials"
version = v"5.2.1" # <-- There is no version 5.2.1, but we need to change version to build for Julia v1.7

# Collection of sources required to build Sundials
sources = [
    GitSource("https://github.com/LLNL/sundials.git",
              "8264ba5614fd9578786e5e8a3ba9f703ff795361"),
    DirectorySource("../bundled@5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials*

    if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
        # For msan, we need to use flang to compile.
        ## Create flang compiler wrapper
        cat /opt/bin/${bb_full_target}/${target}-clang | sed 's/clang/flang/g' > /opt/bin/${bb_full_target}/${target}-flang
        chmod +x /opt/bin/${bb_full_target}/${target}-flang
        ln -s ${WORKSPACE}/x86_64-linux-musl-cxx11/destdir/bin/flang /opt/x86_64-linux-musl/bin/flang
        export FC=${target}-flang
        # Install flang rt libraries to sysroot
        cp ${prefix}/lib/lib{flang*,ompstub*,pgmath*,omp*} /opt/${target}/${target}/sys-root/usr/lib/
        # Install msan runtime (for clang)
        cp -rL ${prefix}/lib/linux/* /opt/x86_64-linux-musl/lib/clang/13.0.1/lib/linux/
        # Install msan runtime (for flang)
        mkdir -p $(dirname $(readlink -f $(which flang)))/../lib/clang/13.0.1/lib/linux
        cp -rL ${prefix}/lib/linux/* $(dirname $(readlink -f $(which flang)))/../lib/clang/13.0.1/lib/linux/

	# Override Fortran in CMake target toolchain
	sed "s/${target}-gfortran/${target}-flang/g" -i ${CMAKE_TARGET_TOOLCHAIN}
    fi

# Set up CFLAGS
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_windows.patch
    # Work around https://github.com/LLNL/sundials/issues/29
    export CFLAGS="-DBUILD_SUNDIALS_LIBRARY"
    # See https://github.com/LLNL/sundials/issues/35
    atomic_patch -p1 ../patches/Sundials_lapackband.patch
    # When looking for KLU libraries, CMake searches only for import libraries,
    # this patch ensures we look also for shared libraries.
    atomic_patch -p1 ../patches/Sundials_findklu_suffixes.patch
elif [[ "${target}" == powerpc64le-* ]]; then
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

# Set up LAPACK
LAPACK_LIBRARIES="-lgfortran"
if [[ ${nbits} == 64 ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_Fortran.patch
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} ${libdir}/libopenblas64_.${dlext}"
else
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} ${libdir}/libopenblas.${dlext}"
fi
if [[ "${target}" == i686-* ]] || [[ "${target}" == x86_64-* ]]; then
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} -lquadmath"
elif [[ "${target}" == powerpc64le-* ]]; then
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} -lgomp -ldl -lm -lpthread"
fi

# Build
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DEXAMPLES_ENABLE_C=OFF \
    -DKLU_ENABLE=ON \
    -DKLU_INCLUDE_DIR="${includedir}" \
    -DKLU_LIBRARY_DIR="${libdir}" \
    -DLAPACK_ENABLE=ON \
    -DLAPACK_LIBRARIES:STRING="${LAPACK_LIBRARIES}" \
    ..
make -j${nproc}
make install

# Move libraries to ${libdir} on Windows
if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/lib/libsundials_*.${dlext} "${libdir}"
fi
"""

# We attempt to build for all defined platforms
platforms = filter!(p -> arch(p) != "powerpc64le", supported_platforms(; experimental=true))
platforms = expand_gfortran_versions(platforms)
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

products = [
    LibraryProduct("libsundials_arkode", :libsundials_arkode),
    LibraryProduct("libsundials_cvode", :libsundials_cvode),
    LibraryProduct("libsundials_cvodes", :libsundials_cvodes),
    LibraryProduct("libsundials_ida", :libsundials_ida),
    LibraryProduct("libsundials_idas", :libsundials_idas),
    LibraryProduct("libsundials_kinsol", :libsundials_kinsol),
    LibraryProduct("libsundials_nvecmanyvector", :libsundials_nvecmanyvector),
    LibraryProduct("libsundials_nvecserial", :libsundials_nvecserial),
    LibraryProduct("libsundials_sunlinsolband", :libsundials_sunlinsolband),
    LibraryProduct("libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
    LibraryProduct("libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
    LibraryProduct("libsundials_sunlinsollapackband", :libsundials_sunlinsollapackband),
    LibraryProduct("libsundials_sunlinsollapackdense", :libsundials_sunlinsollapackdense),
    LibraryProduct("libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
    LibraryProduct("libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
    LibraryProduct("libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
    LibraryProduct("libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
    LibraryProduct("libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
    LibraryProduct("libsundials_sunmatrixband", :libsundials_sunmatrixband),
    LibraryProduct("libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
    LibraryProduct("libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
    LibraryProduct("libsundials_sunnonlinsolfixedpoint", :libsundials_sunnonlinsolfixedpoint),
    LibraryProduct("libsundials_sunnonlinsolnewton", :libsundials_sunnonlinsolnewton),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS_jll"),
    Dependency("SuiteSparse_jll"; compat="~5.10.1"),
    HostBuildDependency("FlangClassic_jll"),
    BuildDependency("LLVMCompilerRT_jll", platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
    BuildDependency("FlangClassic_RTLib_jll", platforms=[Platform("x86_64", "linux"; sanitize="memory")])
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6", julia_compat="1.7")
