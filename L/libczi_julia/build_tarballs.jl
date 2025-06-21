# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libczi_julia"
version = v"0.1.0"

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# Collection of sources required to complete build
sources = [
	GitSource("https://github.com/Agapanthus/libczi_julia.git",
		"1cd9791c8d4bab776a6420d104663123daba37da"),
]

# Bash recipe for building across all platforms
# disable NEON for now, as it causes issues on aarch64 platforms
script = raw"""
cd $WORKSPACE/srcdir/libczi_julia/src
cmake . -B build \
	-DJulia_PREFIX="$prefix" \
	-DCMAKE_INSTALL_PREFIX="$prefix" \
	-DCMAKE_FIND_ROOT_PATH="$prefix" \
	-DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
	-D_UNALIGNED_ACCESS_RESULT=1 \
	-DCMAKE_CXX_STANDARD=17 \
	-DCMAKE_BUILD_TYPE=Release \
	-DENABLE_NEON=OFF \
	-D_NEON_INTRINSICS_RESULT_EXITCODE=0 \
	-D_NEON_INTRINSICS_RESULT_EXITCODE__TRYRUN_OUTPUT=""
cmake --build build --parallel ${nproc}
cmake --install build
install_license $WORKSPACE/srcdir/libczi_julia/COPYING
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# we have to use the same Julia versions as in libjulia_jll - otherwise cxxwrap cannot link against libjulia
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!(p -> os(p) in ["linux", "windows"], platforms)
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
	LibraryProduct("libczi_julia", :libczi_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
	BuildDependency(PackageSpec(name = "libjulia_jll", version = v"1.10.16")),
	Dependency("libcxxwrap_julia_jll"; compat = "~0.14.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version = v"12.1.0")
