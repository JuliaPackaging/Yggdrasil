using BinaryBuilder, Pkg

name = "LUSOL"
version = v"0.1.0"

# Vollständige Git-URL und aktueller Commit-Hash von jacobwilliams/lusol
sources = [
    GitSource("https://github.com", "2d95174d44ec9bf9dabbbd07652c84c11fe56d71")
]

script = raw"""
cd $WORKSPACE/srcdir/lusol

mkdir -p ${libdir}

# Kompiliere alle Fortran-90-Dateien aus src/
gfortran -O3 -fPIC -shared src/*.f90 -o ${libdir}/liblusol.${dlext} -L${libdir} -lblastrampoline

# Lizenzdatei installieren (Pflicht für Yggdrasil)
install_license LICENSE.md
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("liblusol", :liblusol)
]

dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e4508f6-f734-5ecc-8b77-b358cf370619"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"11")


