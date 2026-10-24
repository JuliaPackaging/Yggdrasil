using BinaryBuilder

include(joinpath("..", "..", "platforms", "macos_sdks.jl"))

name = "Toks"
version = v"0.3.2"

sources = [
    GitSource("https://github.com/actual-computer/toks.git",
              "55a5230b08a75916a2b36f92c320f057376833ea"; tag="v$version"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/toks

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done

make -j${nproc} lib

install -Dvm 755 build/*/libtoks.${dlext} -t ${libdir}
install -Dvm 755 build/*/libtoks.a -t ${libdir}
install -Dvm 644 include/toks.h -t ${includedir}
"""

sources, script = require_macos_sdk("14.0", sources, script; deployment_target="10.15")

# Toks only supports x86-64 and AArch64.
# TODO: Fix build on musl by working around the lack of `pthread_attr_setaffinity_np`.
platforms = supported_platforms(; exclude=(p -> libc(p) == "musl" || !(arch(p) in ("x86_64", "aarch64"))))

products = [
    LibraryProduct("libtoks", :libtoks),
    FileProduct("lib/libtoks.a", :libtoks_a),
    FileProduct("include/toks.h", :toks_h),
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"13")
