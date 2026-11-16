# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "catchaMouse16"
version = v"0.2.0"

sources = [
    GitSource("https://github.com/DynamicsAndNeuralSystems/catchaMouse16.git",
              "2ad18283e0f2856e520794602f2f3748857e320d"; tag = "v$(version)"),
]

# Upstream's Makefile builds the `run_feat` executable; its variables are overridden to link the
# same objects into a shared library instead.
script = raw"""
cd ${WORKSPACE}/srcdir/catchaMouse16/C
if [[ ${target} == aarch64-apple-* ]]; then
    extra_ldflags="-L${libdir}/darwin -lclang_rt.osx"
fi
make -j${nproc} \
    CC="${CC}" \
    CFLAGS="-std=c99 -O2 -fPIC" \
    LDFLAGS="-shared ${extra_ldflags}" \
    TARGET_EXEC="libcatchaMouse16.${dlext}"
install -Dvm 755 "libcatchaMouse16.${dlext}" -t "${libdir}"
install_license ../LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libcatchaMouse16", :libcatchaMouse16),
]

llvm_version = v"17.0.6"
dependencies = [
    Dependency("GSL_jll"; compat = "~2.7.3"),
    # libclang_rt.osx.a is required on aarch64-macos to provide `__divdc3`.
    BuildDependency(PackageSpec(name = "LLVMCompilerRT_jll",
                                uuid = "4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version = string(llvm_version));
                    platforms = filter(p -> Sys.isapple(p) && arch(p) == "aarch64", platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_llvm_version = llvm_version)
