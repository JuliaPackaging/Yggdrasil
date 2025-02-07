using BinaryBuilder, Pkg

name = "AquaCrop"
version = v"7.1"

# url = "https://github.com/KUL-RSDA/AquaCrop"
# description = "FAO AquaCrop model of plant growth"

sources = [
    GitSource("https://github.com/KUL-RSDA/AquaCrop",
              "33ae89706ff82c2c119930e47899cd3fad519d6f"),
]

script = raw"""
cd $WORKSPACE/srcdir/AquaCrop*/src/

sed -i -e 's/-march=native//g' Makefile

export FC
make -j${nproc} EXECUTABLE="aquacrop${exeext}" SHARED_LIBRARY="libaquacrop.${dlext}"

# on x86_64-w64-mingw32-libgfortran4, the binary is 'aquacrop'
# on i686-w64-mingw32-libgfortran5, the binary is 'aquacrop.exe'
if [ -f aquacrop.exe ]; then
    mv aquacrop.exe aquacrop
fi
install -Dvm 755 aquacrop "${bindir}"/aquacrop${exeext}
install -Dvm 755 libaquacrop.so "${libdir}"/libaquacrop.${dlext}

install_license ../LICENSE
"""

# we link against libgfortran
# build fails for all libgfortran3 platforms (except freebsd)
platforms = filter(p -> !(libgfortran_version(p) == v"3.0.0"),
                   expand_gfortran_versions(supported_platforms()))

products = [
    ExecutableProduct("aquacrop", :aquacrop),
    LibraryProduct("libaquacrop", :libaquacrop),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
