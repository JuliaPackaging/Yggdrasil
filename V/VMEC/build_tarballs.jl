using BinaryBuilder

name = "VMEC"
version = v"1.0.1"

sources = [
           ArchiveSource("https://gitlab.com/wistell/VMEC2000/-/archive/v$(version).tar",
                         "5178816df28db77cb0aed82d8d3743836431da5b96e38013031e34fdd1d2675b"),
]

script = raw"""
cd $WORKSPACE/srcdir/VMEC*
if [[ ${target} == *mingw* ]]; then
  sed "s/LT_INIT/LT_INIT(win32-dll)/" configure.ac | cat > configure.ac.2
  mv configure.ac.2 configure.ac
  ./autogen.sh
  ./configure CC=gcc FC=gfortran F77=gfortran --with-mkl --enable-tbb --host=$target --target=$target --prefix=$prefix
  # Deal with the issue the gcc doesn't accept -no-undefined at configure step
  sed "s/AM_LDFLAGS =/AM_LDFLAGS =-no-undefined/" Makefile | cat > Makefile.2
  mv Makefile.2 Makefile
  make && make install && make clean

  ./configure CC=gcc FC=gfortran F77=gfortran --with-mkl --host=$target --target=$target --prefix=$prefix
  # Deal with the issue the gcc doesn't accept -no-undefined at configure step
  sed "s/AM_LDFLAGS =/AM_LDFLAGS =-no-undefined/" Makefile | cat > Makefile.2
  mv Makefile.2 Makefile
  make && make install && make clean

  ./configure CC=gcc FC=gfortran F77=gfortran --host=$target --target=$target --prefix=$prefix
  # Deal with the issue the gcc doesn't accept -no-undefined at configure step
  sed "s/AM_LDFLAGS =/AM_LDFLAGS =-no-undefined/" Makefile | cat > Makefile.2
  mv Makefile.2 Makefile
  make && make install && make clean

else
  # Need to apply a fix on apple-darwin* to add missing symlinks for older libmbed* library versions
  if [[ ${target} == *apple-darwin* ]]; then
    # Apply libmbed fixes
    libmbed_path=$(find /workspace/${bb_full_target}/artifacts -name 'libmbedtls.a')
    artifact_id=$(echo $libmbed_path | grep -o -e "artifacts/[a-z0-9]*" | grep -o -e "/[a-z0-9]*" | grep -o -e "[a-z0-9]*")
    mbed_version=$(find ${WORKSPACE}/${bb_full_target}/artifacts/${artifact_id}/lib/ -name "libmbedtls.[0-9]*.[0-9]*.[0-9]*.${dlext}" | grep -o -e "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")
    # mbed_version has a leading dot
    cd ${WORKSPACE}/${bb_full_path}/destdir/lib
    ln -s ../../artifacts/${artifact_id}/lib/libmbedtls${mbed_version}.${dlext} libmbedtls.13.${dlext}
    ln -s ../../artifacts/${artifact_id}/lib/libmbedtls${mbed_version}.${dlext} libmbedtls.12.${dlext}
    ln -s ../../artifacts/${artifact_id}/lib/libmbedcrypto${mbed_version}.${dlext} libmbedcrypto.5.${dlext}
    ln -s ../../artifacts/${artifact_id}/lib/libmbedcrypto${mbed_version}.${dlext} libmbedcrypto.3.${dlext}
    ln -s ../../artifacts/${artifact_id}/lib/libmbedcrypto${mbed_version}.${dlext} libmbedcrypto.0.${dlext}
    ln -s ../../artifacts/${artifact_id}/lib/libmbedx509${mbed_version}.${dlext} libmbedx509.0.${dlext}
    cd ${WORKSPACE}/srcdir/VMEC*
  fi
  # Configure with MKL provided ScaLAPACK
  ./autogen.sh
  ./configure CC=mpicc FC=mpifort F77=mpifort FFLAGS=-O3 FCFLAGS=-O3 --with-mkl --enable-tbb --host=$target --target=$target --prefix=$prefix 
  make && make install && make clean
  
  ./configure CC=mpicc FC=mpifort F77=mpifort FFLAGS=-O3 FCFLAGS=-O3 --with-mkl --host=$target --target=$target --prefix=$prefix 
  make && make install && make clean

  # Configure with OpenBLAS and ScaLAPACK from SCALAPACK_jll
  ./configure CC=mpicc FC=mpifort F77=mpifort FFLAGS=-O3 FCFLAGS=-O3  --host=$target --target=$target --prefix=$prefix
  make && make install && make clean
fi
"""

incompatible_arch = ["i686", "armv6l", "armv7l", "aarch64", "powerpc64le"]
incompatible_os = ["freebsd"]

platforms = expand_gfortran_versions(supported_platforms())

# Filter out libgfortran_version = 3.0.0 which is incompatible with VMEC
platforms = filter(p ->libgfortran_version(p) >= v"4", platforms)

# Filter incompatible architectures and operating systems
for arch in incompatible_arch
  global platforms = filter(p -> p.tags["arch"] != arch, platforms)
end

for os in incompatible_os
  global platforms = filter(p -> p.tags["os"] != os, platforms)
end

# Right now VMEC only works with libc=glibc, filter out any musl dependencies
platforms = filter(p -> (haskey(p.tags, "libc") && p.tags["libc"] != "musl") || !haskey(p.tags, "libc"), platforms)

# The products that we will ensure are always built
# Don't automatically dl_open so that the appropriate 
# library can be loaded on intiation of VMEC.jl
products = [
    LibraryProduct("libvmec_mkl_tbb", :libvmec_mkl_tbb, dont_dlopen = true),
    LibraryProduct("libvmec_mkl_intel", :libvmec_mkl_intel, dont_dlopen = true),
    LibraryProduct("libvmec_openblas_pthread", :libvmec_openblas_pthread, dont_dlopen = true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("MPICH_jll"),
    BuildDependency("OpenBLAS_jll"),
    BuildDependency("MKL_jll"),
    BuildDependency("oneTBB_jll"),
    BuildDependency("NetCDF_jll"),
    BuildDependency("NetCDFF_jll"),
    Dependency("SCALAPACK_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
