using BinaryBuilder, Pkg

name = "LUSOL"
# Untagged: upstream's 1.0.0 plus two Fortran standards fixes
version = v"1.0.1"

sources = [
    GitSource("https://github.com/jacobwilliams/lusol.git",
              "2d95174d44ec9bf9dabbbd07652c84c11fe56d71"),
]

# Upstream builds only with fpm, which the build image lacks
script = raw"""
cd $WORKSPACE/srcdir/lusol
mkdir -pv ${libdir}
${FC} -O3 -fPIC -shared src/lusol_precision.F90 src/lusol.f90 src/lusol_ez.f90 -o ${libdir}/liblusol.${dlext}
install_license LICENSE.md
"""

platforms = expand_gfortran_versions(supported_platforms())

products = [
    LibraryProduct("liblusol", :liblusol),
]

dependencies = [
    # Julia 1.10 ships 1.0.5. 1.3.0 is the oldest release with artifacts for
    # both libgfortran3 and riscv64.
    Dependency("CompilerSupportLibraries_jll", v"1.3.0"; compat="1.0.5"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
