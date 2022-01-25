using BinaryBuilder, Pkg

name = "BVLS"
version = v"1990.03.19"
sources = [
    ArchiveSource("https://cran.r-project.org/src/contrib/bvls_1.4.tar.gz", "a22e1951d280c7d281ffb6d4440938dad83b59a810739e8a1a7ad632e7714aa1")
]

script = raw"""
cd ${WORKSPACE}/srcdir/bvls
mkdir -p "${libdir}"
gfortran -shared -fPIC -o $libdir/libbvls.${dlext} src/bvls.f
install_license inst/COPYRIGHTS
sed -n 10,19p src/bvls.f > LICENSE
install_license LICENSE
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libbvls", :libbvls),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", 
        uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
