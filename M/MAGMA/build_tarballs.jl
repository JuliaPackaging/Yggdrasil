using BinaryBuilder, Pkg

name = "MAGMA"
version = v"2.6.2"
sources = [
    GitSource("https://bitbucket.org/icl/magma", "864fa8b28e8c2905a41fbef32f156695378dc104"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/magma/

cp ../make.inc .

make -j${nproc} sparse-lib
make install prefix=${prefix}
install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [Platform("x86_64", "linux"; libc="glibc")]

# The products that we will ensure are always built
products = [
    LibraryProduct("libmagma", :libmagma; dont_dlopen=true),
    LibraryProduct("libmagma_sparse", :libmagma_sparse; dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=v"11.6.0")),
    Dependency("libblastrampoline_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
