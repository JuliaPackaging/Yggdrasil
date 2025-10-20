# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Silo"
version = v"4.11.1"
sources = [
    # ArchiveSource("https://github.com/LLNL/Silo/releases/download/$(version)/silo-$(version)-bsd-smalltest.tar.xz",
    #               "be05f205180c62443b6f203a48b4e31ed1a3a856bef7bde8e62beb3b6e31ceea"),
    # This isn't quite 4.11.1, it's a few commits later so that we can have `CMakeLists.txt`
    GitSource("https://github.com/LLNL/Silo", "c2414603797c24afb14e9c932707c290003a4bc8"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/Silo

# Do not run target exectutables at build time
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/pdb_detect.patch

# We cannot enable hzip nor fpzip because these are not BSD licenced
cmake -Bbuild \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DSILO_BUILD_FOR_BSD_LICENSE=ON \
      -DSILO_ENABLE_BROWSER=OFF \
      -DSILO_ENABLE_FORTRAN=OFF \
      -DSILO_ENABLE_HDF5=ON \
      -DSILO_ENABLE_JSON=ON \
      -DSILO_ENABLE_PYTHON_MODULE=OFF \
      -DSILO_ENABLE_SHARED=ON \
      -DSILO_ENABLE_SILEX=OFF \
      -DSILO_ENABLE_SILOCK=ON \
      -DSILO_ENABLE_TESTS=OFF

# Provide generated header file
case ${target} in
    arm-*|armv7l-*|i686-*) cp ${WORKSPACE}/srcdir/files/pdform-le32.h build/include/pdform.h;;
    aarch64-*|powerpc64le-*|riscv64-*|x86_64-*) cp ${WORKSPACE}/srcdir/files/pdform-le64.h build/include/pdform.h;;
    *) exit 1;;
esac

cmake --build build --parallel ${nproc}
cmake --install build

install_license COPYRIGHT
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libsiloh5", :libsilo),
]

dependencies = [
    # Without OpenMPI as build dependency the build fails on 32-bit platforms
    BuildDependency(PackageSpec(; name="OpenMPI_jll", version=v"4.1.8"); platforms=filter(p -> nbits(p)==32, platforms)),

    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("libaec_jll"; compat="1.1.4"), # This is the successor of szlib
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
	       julia_compat="1.6")
