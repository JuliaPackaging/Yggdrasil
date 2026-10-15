# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libxsmm"
version = v"1.17.0"

sources = [
    GitSource("https://github.com/libxsmm/libxsmm.git",
              "617beb4a13baa559b689bdea77dce26a5e983ada"),  # 1.17
    DirectorySource("./bundled"),
]

# Only the code generator is built. It is a build-time tool that SeisSol runs on the build host
# to generate small-matrix-multiplication kernels (see HostBuildDependency in the SeisSol recipe).
script = raw"""
cd ${WORKSPACE}/srcdir/libxsmm*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/musl-execinfo.patch
make -j${nproc} generator FC= STATIC=1
install -Dvm755 bin/libxsmm_gemm_generator ${bindir}/libxsmm_gemm_generator
install_license LICENSE.md
"""

# Only needed on the build host, which is x86_64 Linux
platforms = filter(p -> Sys.islinux(p) && arch(p) == "x86_64", supported_platforms())

products = [
    ExecutableProduct("libxsmm_gemm_generator", :libxsmm_gemm_generator),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version = v"9")
