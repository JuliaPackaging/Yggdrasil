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
cd $WORKSPACE/srcdir
mkdir -p build && cd build

cmake ../wrapper \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DJlCxx_DIR=${prefix}/lib/cmake/JlCxx \
    -DJulia_PREFIX=${prefix}

make -j${nproc}
make install

install_license $WORKSPACE/srcdir/LICENSE.md
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
    BuildDependency("Eigen_jll"),  # Required by PROPOSAL's cmake config
    Dependency("PROPOSAL_jll"; compat="~7.6.2"),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.7"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
