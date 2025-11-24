using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

name = "nghttp3"
version = v"1.8.0"
llvm_version = v"13.0.1"

sources = [
    GitSource("https://github.com/ngtcp2/nghttp3.git",
              "96ad17fd71d599b78a11e0ff635eccb7d2f6d649"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/nghttp3

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

git submodule update --init
autoreconf -i
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} --enable-lib-only
make -j${nproc} install
"""

platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

products = [
    LibraryProduct("libnghttp3", :libnghttp3),
]

dependencies = [
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll",
                                uuid="4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version=llvm_version);
                    platforms=filter(p -> sanitize(p) == "memory", platforms))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_llvm_version=llvm_version)
