# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# Workaround for the Pkg issue above, also remove openssl stdlib
openssl = Base.UUID("458c3c95-2e84-50aa-8efc-19380b2a3a95")
delete!(Pkg.Types.get_last_stdlibs(v"1.12.0"), openssl)
delete!(Pkg.Types.get_last_stdlibs(v"1.13.0"), openssl)

# Include libjulia common definitions for Julia version handling
include("../../L/libjulia/common.jl")

name = "PROPOSAL_cxxwrap"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
set -x  # Enable debug output

echo "=== Environment ==="
echo "prefix: ${prefix}"
echo "WORKSPACE: $WORKSPACE"
echo "target: ${target}"
pwd

echo "=== Source directory contents ==="
ls -la $WORKSPACE/srcdir/
ls -la $WORKSPACE/srcdir/wrapper/ || echo "No wrapper directory"

echo "=== Checking prefix structure ==="
echo "--- prefix/lib ---"
ls -la ${prefix}/lib/ 2>&1 | head -30
echo "--- prefix/include ---"
ls -la ${prefix}/include/ 2>&1 | head -30

echo "=== Checking for PROPOSAL ==="
find ${prefix} -name "*PROPOSAL*" -o -name "*proposal*" 2>/dev/null | head -20
ls -la ${prefix}/lib/libPROPOSAL* 2>&1 || echo "No libPROPOSAL found"
ls -la ${prefix}/include/PROPOSAL/ 2>&1 | head -10 || echo "No PROPOSAL headers found"

echo "=== Checking for JlCxx/CxxWrap ==="
ls -la ${prefix}/lib/cmake/ 2>&1 || echo "No cmake directory"
ls -la ${prefix}/lib/cmake/JlCxx/ 2>&1 || echo "No JlCxx cmake directory"
ls -la ${prefix}/lib/libcxxwrap* 2>&1 || echo "No libcxxwrap found"

echo "=== Checking for Julia ==="
ls -la ${prefix}/lib/libjulia* 2>&1 || echo "No libjulia found"
ls -la ${prefix}/include/julia/ 2>&1 | head -10 || echo "No julia headers found"

echo "=== Starting CMake configuration ==="
cd $WORKSPACE/srcdir
mkdir -p build && cd build

cmake ../wrapper \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DJlCxx_DIR=${prefix}/lib/cmake/JlCxx \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    2>&1

echo "=== CMake configuration complete, starting build ==="
make -j${nproc} VERBOSE=1 2>&1

echo "=== Build complete, installing ==="
make install

install_license $WORKSPACE/srcdir/LICENSE.md
echo "=== Done ==="
"""

# Filter Julia versions: remove versions below current LTS (1.10)
filter!(x -> x >= v"1.10", julia_versions)

# Use libjulia platforms for CxxWrap compatibility
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# Filter to platforms supported by both PROPOSAL_jll and libcxxwrap_julia
filter!(p -> libc(p) != "musl", platforms)
filter!(p -> !Sys.iswindows(p), platforms)
filter!(p -> !Sys.isfreebsd(p), platforms)
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "armv7l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libPROPOSAL_cxxwrap", :libPROPOSAL_cxxwrap),
]

# Dependencies
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("PROPOSAL_jll"; compat="7.6"),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.7"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
