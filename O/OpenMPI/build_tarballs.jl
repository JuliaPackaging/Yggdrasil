using BinaryBuilder

name = "OpenMPI"
version = v"4.1.1"
sources = [
    ArchiveSource("https://download.open-mpi.org/release/open-mpi/v$(version.major).$(version.minor)/openmpi-$(version).tar.gz",
                  "d80b9219e80ea1f8bcfe5ad921bd9014285c4948c5965f4156a3831e60776444"),
    DirectorySource("./bundled"),
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/openmpi-*

if [[ "${target}" == *-freebsd* ]]; then
    # Help compiler find `complib/cl_types.h`.
    export CPPFLAGS="-I/opt/${target}/${target}/sys-root/include/infiniband"
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared=yes \
    --enable-static=no \
    --without-cs-fs \
    --with-cross=${WORKSPACE}/srcdir/${target}

# Build the library
make -j${nproc}

# Install the library
make install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
#platforms = supported_platforms()
platforms = filter(p -> !Sys.iswindows(p) && !(arch(p) == "armv6l" && libc(p) == "glibc"), supported_platforms(; experimental=true))
platforms = expand_gfortran_versions(platforms)
    
products = [
    LibraryProduct("libmpi", :libmpi)
    ExecutableProduct("mpiexec", :mpiexec)
]

dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# For the time being we need to use LLVM 11 because LLVM 12 has troubles with GCC 4-5
# on FreeBSD: https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/158
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_llvm_version=v"11")
