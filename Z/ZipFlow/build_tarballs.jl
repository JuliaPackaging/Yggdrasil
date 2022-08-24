using BinaryBuilder

name = "ZipFlow"
version = v"1.0.0"

sources = [GitSource("https://github.com/madler/zipflow.git",
                     "d4d73304252504bbade9aa6f34332bbb00de6664"),
           DirectorySource("./bundled")]

script = raw"""
    cd ${WORKSPACE}/srcdir/zipflow/
    atomic_patch -p1 ../patches/pr3.patch
    atomic_patch -p1 ../patches/windows.patch
    cc zipflow.c -shared -fPIC -std=gnu99 -o ${libdir}/libzipflow.${dlext} -I${includedir} -L${libdir} -lz
    install_license LICENSE
    """

platforms = supported_platforms()

products = [LibraryProduct("libzipflow", :libzipflow)]

dependencies = [Dependency("Zlib_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
