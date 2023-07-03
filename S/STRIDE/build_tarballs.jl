using BinaryBuilder, Pkg
using BinaryBuilderBase: Dependency

name = "STRIDE"
version = v"1.0.0"

# url = "https://github.com/m3g/stride"
# description = "Protein secondary structure assignment from atomic coordinates"

sources = [
    GitSource("https://github.com/m3g/stride",
              "dfc94c82f1ec93a8852099f5f18995bb61fe5999"),
]

script = raw"""
cd $WORKSPACE/srcdir/stride*/

cd src
make
install -Dvm 755 "stride" "${bindir}/stride${exeext}"

# build shared library
mkdir -p "${libdir}"
"${CC}" -shared -g -O2 -o "${libdir}"/libstride.${dlext} *.o -lm

install_license ../LICENSE
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("stride", :stride_exe), # stride collides with Base.stride...
    LibraryProduct("libstride", :libstride),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"5")
