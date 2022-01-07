using BinaryBuilder

name = "SCALAPACK32"
version = v"2.1.0"

sources = [
  ArchiveSource("http://www.netlib.org/scalapack/scalapack-$(version).tgz",
                "61d9216cf81d246944720cfce96255878a3f85dec13b9351f1fa0fd6768220a6"),
  DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/scalapack-*

# the patch prevents running foreign executables, which fails on most platforms
# we instead set CDEFS manually below
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix}
             -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
             -DCMAKE_BUILD_TYPE=Release
             -DBUILD_SHARED_LIBS=ON)

if [[ "${target}" == i686-*  ]] || [[ "${target}" == x86_64-*  ]]; then
  CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran -lquadmath")
else
  if [[ "${target}" == powerpc64le-linux-gnu || "${target}" == *darwin* ]]; then
    # special case for CMake to discover MPI_Fortran
    CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran -L/opt/${target}/${target}/sys-root/usr/lib64 -lpthread -lrt" \
                  -DCMAKE_SHARED_LINKER_FLAGS="-lgfortran -L/opt/${target}/${target}/sys-root/usr/lib64 -lpthread -lrt" \
                  -DMPI_Fortran_LINK_FLAGS="-Wl,-rpath -Wl,/workspace/destdir/lib -Wl,--enable-new-dtags -L/workspace/destdir/lib -Wl,-L/opt/${target}/${target}/sys-root/usr/lib64 -Wl,-lpthread -Wl,-lrt")
  else
    CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran")
  fi
fi

OPENBLAS=(-lopenblas)
FFLAGS=(-cpp -ffixed-line-length-none)

if [[ "${target}" == powerpc64le-linux-gnu ]]; then
  OPENBLAS+=(-lgomp)
fi

CMAKE_FLAGS+=(-DCMAKE_Fortran_FLAGS=\"${FFLAGS[*]}\" \
              -DCMAKE_C_FLAGS=\"${FFLAGS[*]}\" \
              -DBLAS_LIBRARIES=\"${OPENBLAS[*]}\" \
              -DLAPACK_LIBRARIES=\"${OPENBLAS[*]}\")

export CDEFS="Add_"

mkdir build && cd build
cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc} all
make install
"""

# OpenMPI and MPICH are not precompiled for Windows
# Can't get the code to build for PowerPC with libgfortran3
platforms = expand_gfortran_versions(filter!(p -> !Sys.iswindows(p), supported_platforms(; experimental=true)))

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack", :libscalapack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MPICH_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
