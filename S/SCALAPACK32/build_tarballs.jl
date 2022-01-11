using BinaryBuilder, Pkg

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

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix} \
             -DCMAKE_FIND_ROOT_PATH=${prefix} \
             -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
             -DCMAKE_BUILD_TYPE=Release \
             -DBLAS_LIBRARIES="-lopenblas" \
             -DLAPACK_LIBRARIES="-lopenblas" \
             -DBUILD_SHARED_LIBS=ON \
             -DMPIEXEC="${bindir}/mpirun")

if [[ "${target}" == i686-*  ]] || [[ "${target}" == x86_64-*  ]]; then
  CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran -lquadmath")
else
  CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran")
fi

export CDEFS="Add_"

mkdir build
cd build
cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc} all
make install
"""

# OpenMPI and MPICH are not precompiled for Windows
# Can't get the code to build for PowerPC with libgfortran3
platforms = expand_gfortran_versions(supported_platforms(; exclude=p -> Sys.iswindows(p) || arch(p) == "powerpc64le"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack", :libscalapack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
