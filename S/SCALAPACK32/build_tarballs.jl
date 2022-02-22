using BinaryBuilder, Pkg

name = "SCALAPACK32"
version = v"2.2.0"

sources = [
  ArchiveSource("https://github.com/Reference-ScaLAPACK/scalapack/archive/refs/tags/v$(version).tar.gz",
                "8862fc9673acf5f87a474aaa71cd74ae27e9bbeee475dbd7292cec5b8bcbdcf3"),
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
             -DSCALAPACK_BUILD_TESTS=OFF \
             -DMPI_BASE_DIR="${prefix}")

if [[ "${target}" == i686-*  ]] || [[ "${target}" == x86_64-*  ]]; then
  CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran -lquadmath")
else
  CMAKE_FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lgfortran")
fi

if [[ "${target}" == aarch64-apple-darwin* ]]; then
  CMAKE_FLAGS+=(-DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch")
fi

export CDEFS="Add_"

mkdir build
cd build
cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc} all
make install

mv -v ${libdir}/libscalapack.${dlext} ${libdir}/libscalapack32.${dlext}

# If there were links that are now broken, fix 'em up
for l in $(find ${prefix}/lib -xtype l); do
  if [[ $(basename $(readlink ${l})) == libscalapack ]]; then
    ln -vsf libscalapack32.${dlext} ${l}
  fi
done

PATCHELF_FLAGS=()

# ppc64le and aarch64 have 64KB page sizes, don't muck up the ELF section load alignment
if [[ ${target} == aarch64-* || ${target} == powerpc64le-* ]]; then
  PATCHELF_FLAGS+=(--page-size 65536)
fi

if [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
  patchelf ${PATCHELF_FLAGS[@]} --set-soname libscalapack32.${dlext} ${libdir}/libscalapack32.${dlext}
elif [[ ${target} == *apple* ]]; then
  install_name_tool -id libscalapack32.${dlext} ${libdir}/libscalapack32.${dlext}
fi
"""

platforms = expand_gfortran_versions(supported_platforms(; exclude=Sys.iswindows))

# The products that we will ensure are always built
products = [
    LibraryProduct("libscalapack32", :libscalapack32),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
