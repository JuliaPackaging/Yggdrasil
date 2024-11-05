using BinaryBuilder

# Collection of sources required to build Arpack
name = "Arpack32"

version = v"3.9.1"

sources = [
    GitSource("https://github.com/opencollab/arpack-ng.git",
              "40329031ae8deb7c1e26baf8353fa384fc37c251"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/arpack-ng*

# arpack tests require finding libgfortran when linking with C linkers,
# and gcc doesn't automatically add that search path.  So we do it for it with `rpath-link`.
EXE_LINK_FLAGS=()
if [[ ${target} != *darwin* ]]; then
    EXE_LINK_FLAGS+=("-Wl,-rpath-link,/opt/${target}/${target}/lib")
fi

FFLAGS="${FFLAGS} -O3 -fPIE -ffixed-line-length-none -fno-optimize-sibling-calls -cpp"

mkdir build
cd build
export LDFLAGS="${EXE_LINK_FLAGS[@]} -L${libdir} -lpthread"
cmake .. -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DCMAKE_BUILD_TYPE=Release \
    -DEXAMPLES=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DBLAS_LIBRARIES="-lopenblas" \
    -DLAPACK_LIBRARIES="-lopenblas" \
    -DCMAKE_Fortran_FLAGS="${FFLAGS}"

make -j${nproc} VERBOSE=1
make install VERBOSE=1

# Delete the extra soversion libraries built. https://github.com/JuliaPackaging/Yggdrasil/issues/7
if [[ "${target}" == *-mingw* ]]; then
    rm -f ${libdir}/lib*.*.${dlext}
    rm -f ${libdir}/lib*.*.*.${dlext}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We enable the full
# combinatorial explosion of GCC versions because this package most
# definitely links against libgfortran.
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libarpack", :libarpack32),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
	       julia_compat="1.8", clang_use_lld=false, preferred_gcc_version=v"6")
