using BinaryBuilder, Pkg

name = "dist_m4ri"
version = v"0.0.1"

sources = [
    GitSource("https://github.com/QEC-pages/dist-m4ri.git",
              "0c540cb766f5538d9a89152dc875ae5a357ee6c6")
]

script = raw"""
cd $WORKSPACE/srcdir/dist-m4ri/src/
make -j${nproc} CC=$CC CXX=$CXX
install -Dvm 755 "dist-m4ri${exeext}"  -t "${bindir}"
"""

platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p) || Sys.isfreebsd(p) || Sys.iswindows(p), supported_platforms())

products = [
    ExecutableProduct("dist_m4ri", :dist_m4ri)
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
