# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xyce"
version = v"7.2.0"

# Collection of sources required to complete build
sources = [
            GitSource("https://github.com/Xyce/Xyce.git", "a61faef4bfb2f36f1aa7cc44264bbbb66fbaac11"),
            GitSource("https://github.com/westes/flex.git", "d69a58075169410324fe49666f6641ba6a9d1f91"),
            DirectorySource("./bundled")
          ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd flex
apk add texinfo
./autogen.sh
./configure --prefix=${prefix} --host=${target}
make -j${nprocs}
make install
cd ..
cd Xyce
if [[ $target != *gnu ]] ; then
        atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cross.patch
fi
./bootstrap
cd ..
mkdir buildx
cd buildx
/workspace/srcdir/Xyce/./configure --enable-shared --disable-mpi --prefix=${prefix} LDFLAGS="-L${libdir} -lopenblas" CPPFLAGS="-I/$prefix/include" --host=${target}
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
   
platforms = filter(p -> (!Sys.iswindows(p) &&
                         !Sys.isapple(p) &&
                         !Sys.isfreebsd(p) &&
                         arch(p) ∉ ("armv7l", "powerpc64le", "aarch64")),
                   supported_platforms())
    
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxyce", :libxyce),
    LibraryProduct("libNeuronModels", :libNeuronModels),
    LibraryProduct("libADMS", :libADMS),
    ExecutableProduct("Xyce", :Xyce)
]

# Dependencies that must be installed before this package can be built
dependencies = [
                    Dependency(PackageSpec(name="Trilinos_jll", uuid="b6fd3212-6f87-5999-b9ea-021e9cd21b17"))
                    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
                    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
                    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
                    Dependency(PackageSpec(name="Help2man_jll", uuid="b065d96c-5f5a-5e02-95cc-818e6b3b761f"))
                    Dependency(PackageSpec(name="Gettext_jll", uuid="78b55507-aeef-58d4-861c-77aaff3498b1"))
                    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
                ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
