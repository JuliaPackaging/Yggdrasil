#=
BINARYBUILDER_RUNNER=privileged julia build_tarballs.jl --verbose --debug       
=#

using BinaryBuilder
using Pkg

version = v"2.3.0" # libIGL version, see below:

sources = [
	DirectorySource("./iglwrap"),
	# 2.3.0 stable release:
	GitSource("https://github.com/libigl/libigl.git",
		"e60423e28c86b6aa2a3f6eb0112e8fd881f96777"),
	FileSource("https://www.gnu.org/licenses/gpl-3.0.txt",
		"3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986"),
]

script = raw"""
cd $WORKSPACE/srcdir
mkdir -p build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_MODULE_PATH=${WORKSPACE}/srcdir/libigl/cmake\; \
    -DCGAL_test_cpp_version_RUN_RES=0 \
    -DCGAL_test_cpp_version_RUN_RES__TRYRUN_OUTPUT="$(c++ -xc++ - -E -dM < /dev/null | grep -oP '__cplusplus \K.*')" \
    ..
make -j${nproc}
make install
install_license gpl-3.0.txt
"""

products = [
	LibraryProduct("libiglwrap", :libiglwrap;
		dlopen_flags=[:RTLD_NOW,:RTLD_LOCAL])
]

platforms = [
	# 2021-10-30: LibIGL won't compile on at least MacOS right now, but
	# works on the following platforms:
	Platform("x86_64", "linux"),
]
# platforms = supported_platforms()

platforms = expand_cxxstring_abis(platforms)


dependencies = [
  Dependency("boost_jll", compat="~1.71"),
	Dependency("GMP_jll"),
	Dependency("MPFR_jll"),
	Dependency("OpenBLAS_jll"),
 ]

build_tarballs(ARGS, "IGLWrap", version,
    sources,
    script,
    platforms,
    products,
    dependencies,
)
