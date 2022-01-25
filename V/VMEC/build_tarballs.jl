using BinaryBuilder, Pkg

name = "VMEC"
version = v"1.0.3"

sources = [
    ArchiveSource("https://gitlab.com/wistell/VMEC2000/-/archive/v$(version).tar",
                  "cee46dfeb452d2dd79811f8b66fdb6e1a38975d276e71b5531474b03024a5a8f"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/VMEC*
if [[ ${target} == *mingw* ]]; then
  sed "s/LT_INIT/LT_INIT(win32-dll)/" configure.ac | cat > configure.ac.2
  mv configure.ac.2 configure.ac
  ./autogen.sh
  ./configure CC=gcc FC=gfortran F77=gfortran --build=${MACHTYPE} --with-mkl --host=${target} --target=${target} --prefix=${prefix}
  # Deal with the issue that gcc doesn't accept -no-undefined at configure step
  sed "s/AM_LDFLAGS =/AM_LDFLAGS =-no-undefined/" Makefile | cat > Makefile.2
  mv Makefile.2 Makefile
  make && make install && make clean

  ./configure CC=gcc FC=gfortran F77=gfortran --build=${MACHTYPE} --host=${target} --target=${target} --prefix=${prefix}
  # Deal with the issue that gcc doesn't accept -no-undefined at configure step
  sed "s/AM_LDFLAGS =/AM_LDFLAGS =-no-undefined/" Makefile | cat > Makefile.2
  mv Makefile.2 Makefile
  make && make install && make clean

else
  # Configure with MKL provided ScaLAPACK
  ./autogen.sh
  ./configure CC=mpicc FC=mpifort F77=mpifort FFLAGS=-O3 FCFLAGS=-O3 --with-mkl --build=${MACHTYPE} --host=${target} --target=${target} --prefix=${prefix}
  make && make install && make clean

  # Configure with OpenBLAS and ScaLAPACK from SCALAPACK_jll
  ./configure CC=mpicc FC=mpifort F77=mpifort FFLAGS=-O3 FCFLAGS=-O3 --build=${MACHTYPE}  --host=${target} --target=${target} --prefix=${prefix}
  make && make install && make clean
fi
"""

platforms = expand_gfortran_versions(supported_platforms())

# Filter out libgfortran_version = 3.0.0 which is incompatible with VMEC
filter!(p ->libgfortran_version(p) >= v"4", platforms)

# Filter incompatible architectures and operating systems
filter!(p -> arch(p) == "x86_64", platforms)
filter!(!Sys.isfreebsd, platforms)

# Right now VMEC only works with libc=glibc, filter out any musl dependencies
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
# Don't automatically dl_open so that the appropriate 
# library can be loaded on intiation of VMEC.jl
products = [
    LibraryProduct("libvmec_mkl", :libvmec_mkl, dont_dlopen = true),
    LibraryProduct("libvmec_openblas", :libvmec_openblas, dont_dlopen = true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # MbedTLS is an indirect dependency, fix the version for building 
    BuildDependency(PackageSpec(name = "MbedTLS_jll", version = v"2.24.0")),
    Dependency("MPICH_jll"; platforms=filter(!Sys.iswindows, platforms)),
    Dependency("OpenBLAS_jll"),
    Dependency("SCALAPACK_jll"; platforms=filter(!Sys.iswindows, platforms)),
    Dependency("MKL_jll", v"2020.1.216"),
    Dependency("NetCDF_jll"),
    Dependency("NetCDFF_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
