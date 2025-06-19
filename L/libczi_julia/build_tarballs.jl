# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libczi_julia"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Agapanthus/libczi_julia.git", 
        "95bde92f18428e89a0e1542ff8257fd71710dc6a")
]

# Bash recipe for building across all platforms
# disable NEON for now, as it causes issues on aarch64 platforms
script = raw"""
cd $WORKSPACE/srcdir
cmake -S $WORKSPACE/srcdir/libczi_julia/src \
	-B build \
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
platforms = supported_platforms(; exclude=(p -> (arch(p) == "i686" && libc(p) == "musl") || !(os(p) in ["linux", "windows"])))

# The products that we will ensure are always built
products = [
    LibraryProduct("libczi_julia", :libczi_julia)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"))
    Dependency(PackageSpec(name="libjulia_jll", uuid="5ad3ddd2-0711-543a-b040-befd59781bbf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"12.1.0")
