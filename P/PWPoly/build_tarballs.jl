using BinaryBuilder, Pkg

name = "PWPoly"
version = v"0.1.0"

sources = [
    # PWPoly source 
    GitSource("https://gitlab.inria.fr/gamble/pwpoly.git",
              "398a40cafd1802546e13b5cad1c658ec3319a3f6"),

    # FLINT 2.8.5
    GitSource("https://github.com/flintlib/flint2.git",
              "25aad90b890e2cb4a3a949f6311f0713449bb125"),

    # Arb 2.22.1
    GitSource("https://github.com/fredrik-johansson/arb.git",
              "b401d7cc3433f34de9f4c6cd518dfaf1bfac7484"),
]

script = raw"""
cd $WORKSPACE/srcdir

# ${includedir} and ${libdir} are BinaryBuilder variables pointing to
# the directories where GMP_jll and MPFR_jll are unpacked.
# -fPIC is needed since static .a files will be linked into a shared .so/.dylib/.dll.
export CFLAGS="${CFLAGS} -I${includedir} -fPIC"
export LDFLAGS="${LDFLAGS} -L${libdir}"

STAGING=${WORKSPACE}/staging
mkdir -p ${STAGING}

# ── Build FLINT 2.8.5 (static only) ──
cd $WORKSPACE/srcdir/flint2
./configure \
    --prefix=${STAGING} \
    --with-gmp=$prefix \
    --with-mpfr=$prefix \
    --disable-shared \
    CC="${CC}" CXX="${CXX}" AR="${AR}"
make -j${nproc}
make install
cp -f libflint.a ${STAGING}/lib/ 2>/dev/null || true
cd ..

# ── Build Arb 2.22.1 (static only) ──
cd $WORKSPACE/srcdir/arb
./configure \
    --prefix=${STAGING} \
    --with-flint=${STAGING} \
    --with-gmp=$prefix \
    --with-mpfr=$prefix \
    --disable-shared \
    CC="${CC}" CXX="${CXX}" AR="${AR}"
make -j${nproc}
make install
cp -f libarb.a ${STAGING}/lib/ 2>/dev/null || true
cd ..

# ── Build PWPoly (link statically against FLINT/Arb) ──
cd pwpoly
sed -i 's/-march=native//g' CMakeLists.txt

# Patch CMakeLists.txt: remove the global link_libraries for FLINT/ARB/GMP/MPFR
# and instead control the exact link order on the pwpoly target.
# --whole-archive ensures ALL FLINT/Arb symbols are included (circular deps),
# and GMP/MPFR must come AFTER to resolve their references (critical on Windows).
sed -i '/^link_libraries(${FLINT_LIB})$/d' CMakeLists.txt
sed -i '/^link_libraries(${ARB_LIB})$/d' CMakeLists.txt
sed -i '/^link_libraries(${GMP_LIB})$/d' CMakeLists.txt
sed -i '/^link_libraries(${MPFR_LIB})$/d' CMakeLists.txt
# add RUNTIME DESTINATION so cmake installs the .dll (for Windows)
sed -i 's|LIBRARY DESTINATION lib|LIBRARY DESTINATION lib\n        RUNTIME DESTINATION bin|' CMakeLists.txt
if [[ "${target}" == *apple* ]]; then
    sed -i 's|target_link_libraries(pwpoly ${LIBRARIES})|target_link_libraries(pwpoly -Wl,-force_load,${FLINT_LIB} -Wl,-force_load,${ARB_LIB} ${GMP_LIB} ${MPFR_LIB} m)|' CMakeLists.txt
else
    sed -i 's|target_link_libraries(pwpoly ${LIBRARIES})|target_link_libraries(pwpoly -Wl,--whole-archive ${FLINT_LIB} ${ARB_LIB} -Wl,--no-whole-archive ${GMP_LIB} ${MPFR_LIB} m)|' CMakeLists.txt
fi

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DFLINT_INCLUDE_DIR=${STAGING}/include \
    -DARB_INCLUDE_DIR=${STAGING}/include \
    -DFLINT_LIB:FILEPATH=${STAGING}/lib/libflint.a \
    -DARB_LIB:FILEPATH=${STAGING}/lib/libarb.a \
    -DBUILD_SHARED_LIBS=ON

cmake --build . --target pwpoly -j${nproc}
cmake --install .

install_license $WORKSPACE/srcdir/pwpoly/LICENSE.LESSER
"""

platforms = supported_platforms()
filter!(p -> libc(p) != "musl", platforms)  # FLINT 2.8.5 uses cpu_set_t (glibc-only)


products = [
    LibraryProduct("libpwpoly", :libpwpoly),
]

dependencies = [
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
]

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"7")
