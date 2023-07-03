using BinaryBuilder, Pkg
using BinaryBuilderBase: Dependency

name = "STRIDE"
version = v"1.0.0"

# url = "https://github.com/m3g/stride"
# description = "Protein secondary structure assignment from atomic coordinates"

sources = [
    GitSource("https://github.com/m3g/stride",
              "79aeff9a7e875eee17f3b34364a1db5da2dc222d"),
]

script = raw"""
cd $WORKSPACE/srcdir/

make CC="${CC} -g -O2 -fPIC -Wall"
install -Dvm 755 "stride" "${bindir}/stride${exeext}"

# build shared library
mkdir -p "${libdir}"
"${CC}" -shared -O2 -g -o "${libdir}"/libstride.${dlext} *.o

install_license doc/stride.doc
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
