using BinaryBuilder, Pkg

name = "libfabric"
version = v"2.0.0"

sources = [
    GitSource("https://github.com/ofiwg/libfabric", "2ee68f6051e90a59d7550d94a331fdf5e038db90"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libfabric

./autogen.sh
./configure --build=${MACHTYPE} --host=${target} --prefix=${prefix} --with-dlopen
make -j${nproc}
make install
"""

# libfabric only builds on Linux, OS X, and FreeBSD
platforms = supported_platforms(; exclude=Sys.iswindows)

products = [
    LibraryProduct("libfabric", :libfabric),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# We need at least GCC 5 for `<stdatomic.h>`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
