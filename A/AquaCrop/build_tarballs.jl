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
make -j${nproc}

# the executable and library built by the Makefile always have the
# same file endings, regardless of platform
install -Dvm 755 aquacrop "${bindir}"/aquacrop${exeext}
install -Dvm 755 libaquacrop.so "${libdir}"/libaquacrop.${dlext}

install_license ../LICENSE
"""

# we link against libgfortran
# build fails for i686-linux-gnu-libgfortran3
platforms = filter(p -> !(arch(p) == "i686" && os(p) == "linux" && libgfortran_version(p) == v"3.0.0"),
                   expand_gfortran_versions(supported_platforms()))

products = [
    ExecutableProduct("aquacrop", :aquacrop),
    LibraryProduct("libaquacrop", :libaquacrop),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
