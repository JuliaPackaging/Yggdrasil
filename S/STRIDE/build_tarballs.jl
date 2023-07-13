using BinaryBuilder, Pkg
using BinaryBuilderBase: Dependency

name = "STRIDE"
version = v"1.0.0"

# url = "https://github.com/m3g/stride"
# description = "Protein secondary structure assignment from atomic coordinates"

sources = [
    GitSource("https://github.com/m3g/stride",
              "71bb229679248b7ee6c39d0e95baca3eb7453427"),
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
