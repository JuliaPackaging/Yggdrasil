using BinaryBuilder, Pkg

name = "BVLS"
version = v"1990.03.19"
sources = [
    DirectorySource("./bundled/"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${libdir}"
gfortran -shared -fPIC -o $libdir/libbvls.${dlext} bvls.f
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
