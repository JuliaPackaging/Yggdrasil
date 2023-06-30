using BinaryBuilder, Pkg
using BinaryBuilderBase: Dependency

name = "Stride"
version = v"1.0.0"

# url = "https://github.com/MDAnalysis/stride"
# description = "Protein secondary structure assignment from atomic coordinates"

sources = [
    GitSource("https://github.com/MDAnalysis/stride",
              "867a5eb0f2479cb16615512a53ee472c54649505"),
]

script = raw"""
cd $WORKSPACE/srcdir/stride*/

cd src

make CC="${CC} -g -O2 -fPIC -Wall"
install -Dvm 755 "stride" "${bindir}/strid${exeext}"

# build shared library
mkdir -p "${libdir}"
"$CC" -shared -O2 -g -o "${libdir}"/libstride.${dlext} *.o

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
