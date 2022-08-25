using BinaryBuilder

name = "ZipFlow"
version = v"1.1.0"

sources = [GitSource("https://github.com/madler/zipflow.git",
                     "913ef458c51504d1f461f6d3a24d4a1a9bdc2bcc")]

script = raw"""
    cd ${WORKSPACE}/srcdir/zipflow/
    cc zipflow.c -shared -fPIC -std=gnu99 -o ${libdir}/libzipflow.${dlext} -I${includedir} -L${libdir} -lz
    install_license LICENSE
    """

platforms = supported_platforms()

products = [LibraryProduct("libzipflow", :libzipflow)]

dependencies = [Dependency("Zlib_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
