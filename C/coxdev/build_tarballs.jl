# DRAFT BinaryBuilder recipe for coxdev_jll (for JuliaPackaging/Yggdrasil,
# as C/coxdev/build_tarballs.jl). Not submitted. It builds libcoxdev_c, the C
# API over coxdev's header-only C++ library, for every platform BinaryBuilder
# supports; CoxDev.jl would then depend on coxdev_jll instead of COXDEV_C_LIB.
#
# Try it locally (needs Docker or BinaryBuilder's sandbox):
#     julia --project=. build_tarballs.jl --verbose --debug aarch64-apple-darwin
using BinaryBuilder, Pkg

name = "coxdev"
version = v"0.4.0"   # the coxdev release with the header-only library and the C API

sources = [
    # a tagged coxdev release (fill in the commit of the tag)
    GitSource("https://github.com/jonathan-taylor/coxdev.git",
              "6d42811c52466a5604972ff9ff84795591ab0bfa"),
]

# Eigen comes from Eigen_jll (headers only), not coxdev's eigen submodule
script = raw"""
cd ${WORKSPACE}/srcdir/coxdev/cpp/capi
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DEIGEN_INCLUDE_DIR=${includedir}/eigen3 \
    -DCOXDEV_C_TESTS=OFF
cmake --build build --parallel ${nproc}
install -Dvm 755 build/libcoxdev_c.${dlext} ${libdir}/libcoxdev_c.${dlext}
install -Dvm 644 ../include/coxdev_c_api.h ${includedir}/coxdev_c_api.h
install_license ${WORKSPACE}/srcdir/coxdev/LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libcoxdev_c", :libcoxdev_c),
]

dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70")),
]

# C++17 for coxdev; GCC 8 is the first with full C++17 support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"8")
