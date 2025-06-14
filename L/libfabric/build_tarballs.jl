using BinaryBuilder, Pkg

name = "libfabric"
version = v"1.22.0"
# Note: Version 2.0.0 seems to require glibc 2.26, which is newer than our default dependency.
# We shouldn't switch just yet.
# version = v"2.0.0"

sources = [
    GitSource("https://github.com/ofiwg/libfabric", "159219639b7fd69d140892120121bbb4d694e295"), # 1.22.0
    # GitSource("https://github.com/ofiwg/libfabric", "2ee68f6051e90a59d7550d94a331fdf5e038db90"), # 2.0.0
]

script = raw"""
cd ${WORKSPACE}/srcdir/libfabric

args=(--with-dlopen)
if [[ ${target} == *freebsd* ]]; then
    # verbs on FreeBSD requires the Linux kernel header files
    # (Maybe a cross-compiling bug?)
    args+=(--enable-verbs=no)
fi

./autogen.sh
# export CPPFLAGS=-I${prefix}/usr/include
./configure --build=${MACHTYPE} --host=${target} --prefix=${prefix} ${args[@]}
make -j${nproc}
make install
"""

# libfabric only builds on Linux, OS X, and FreeBSD
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)

products = [
    LibraryProduct("libfabric", :libfabric),
]

# # Platforms where we need a newer glibc
# glibc_platforms = filter(p -> Sys.islinux(p) && arch(p) == "x86_64", platforms)

dependencies = [
    # # We need the header file `bits/types/struct_iovec.h` that was added in glibc 2.26
    # BuildDependency(PackageSpec(name="Glibc_jll", version=v"2.34")),#; platforms=glibc_platforms),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# We need at least GCC 5 for `<stdatomic.h>`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
