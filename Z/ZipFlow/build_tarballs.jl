using BinaryBuilder

name = "ZipFlow"
version = v"1.0.0"

sources = [GitSource("https://github.com/madler/zipflow.git",
                     "d4d73304252504bbade9aa6f34332bbb00de6664")]

script = raw"""
    cd ${WORKSPACE}/srcdir/zipflow/
    cc zipflow.c -shared -std=c99 -o libzipflow.${dlext} -I${includedir} -L${libdir} -lz
    mv libzipflow.${dlext} ${libdir}/
    install_license LICENSE
    """

platforms = supported_platforms(; experimental=true)

products = [LibraryProduct("libzipflow", :libzipflow)]

dependencies = [Dependency("Zlib_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
