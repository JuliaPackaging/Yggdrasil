#=
BINARYBUILDER_RUNNER=privileged julia build_tarballs.jl --verbose --debug       
=#

using BinaryBuilder
using Pkg

version = v"2.4.0" # libIGL version, see below:

sources = [
	DirectorySource("./iglwrap"),
	# 2.4.0 stable release as indicated in ./iglwrap/cmake/libigl.cmake file
]

script = raw"""
cd $WORKSPACE/srcdir
mkdir -p build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    `# We can't run try_run in cross-compilation mode, pass the exit code and stdout of the program (the value of __cplusplus macro)` \
    -DCGAL_test_cpp_version_RUN_RES=0 \
    -DCGAL_test_cpp_version_RUN_RES__TRYRUN_OUTPUT="$(c++ -xc++ - -E -dM < /dev/null | grep -oP '__cplusplus \K.*')" \
    ..
make -j${nproc}
make install
install_license /usr/share/licenses/GPL-3.0+
"""

products = [
	LibraryProduct("libiglwrap", :libiglwrap;
		dlopen_flags=[:RTLD_NOW,:RTLD_LOCAL])
]

platforms = [
    Platform("x86_64", "linux"), Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
]

platforms = expand_cxxstring_abis(platforms)


dependencies = [
    Dependency("GMP_jll"; compat="6.2.0"),
    Dependency("MPFR_jll"; compat="4.1.0"),
]

build_tarballs(ARGS, "IGLWrap", version,
    sources,
    script,
    platforms,
    products,
    dependencies;  
    preferred_gcc_version=v"8", julia_compat="1.6"
)
