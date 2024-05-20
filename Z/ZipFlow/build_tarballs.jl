using BinaryBuilder

name = "ZipFlow"
version = v"1.4.0"

sources = [GitSource("https://github.com/madler/zipflow.git",
                     "dd2c33bc91ef2142c96472656cb540ae8c1d8281")]

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
