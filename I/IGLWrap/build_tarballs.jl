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
		"e60423e28c86b6aa2a3f6eb0112e8fd881f96777")
]

script = raw"""
cd $WORKSPACE/srcdir
ls -l ${WORKSPACE} >&2
ls -l ${WORKSPACE}/srcdir >&2
mkdir build||true; cd build
cmake \
  -DCMAKE_INSTALL_PREFIX=$prefix \
	-DCMAKE_MODULE_PATH=${WORKSPACE}/srcdir/libigl/cmake\; \
	..
make && make install
echo "blah" >&2


install_license ${WORKSPACE}/srcdir/LICENSE
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
