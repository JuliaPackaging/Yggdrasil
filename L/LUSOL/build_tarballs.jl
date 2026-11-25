using BinaryBuilder, Pkg

name = "LUSOL"
version = v"0.1.0"

# Git-URL and Commit-Hash of jacobwilliams/lusol
sources = [
    GitSource("https://github.com/jacobwilliams/lusol.git", "2d95174d44ec9bf9dabbbd07652c84c11fe56d71")
]

script = raw"""
cd $WORKSPACE/srcdir/lusol

mkdir -p ${libdir}

${FC} -O3 -fPIC -shared src/lusol_precision.F90 src/lusol.f90 src/lusol_ez.f90 -o ${libdir}/liblusol.${dlext}

install_license LICENSE.md
"""

platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # only 64-bit platforms!
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("liblusol", :liblusol)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")


