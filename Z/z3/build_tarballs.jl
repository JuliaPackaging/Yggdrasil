# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "z3"
version = v"4.11.2"
julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Z3Prover/z3/archive/z3-$(version).tar.gz",
                  "e3a82431b95412408a9c994466fad7252135c8ed3f719c986cd75c8c5f234c7e"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

macfix = raw"""
# See https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1185
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # work around macOS SDK issue
    #     /workspace/srcdir/z3/src/ast/ast.h:: 189error:: 47:'get<unsigned int, int, ast *,
    #         symbol, zstring *, rational *, double, unsigned int>' is unavailable:
    #         introduced in macOS 10.14
    export MACOSX_DEPLOYMENT_TARGET=10.15
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi
"""

# Bash recipe for building across all platforms
script = macfix * raw"""
cd $WORKSPACE/srcdir/z3-*

mkdir z3-build && cd z3-build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH="${prefix}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DZ3_USE_LIB_GMP=True \
    -DZ3_BUILD_JULIA_BINDINGS=True \
    -DJulia_PREFIX="${prefix}" \
    ..
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/z3-*/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libz3", :libz3),
    LibraryProduct("libz3jl", :libz3jl),
    ExecutableProduct("z3", :z3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency(get_addable_spec("GMP_jll", v"6.2.0+5")),
    Dependency("libcxxwrap_julia_jll"),
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms,
               products, dependencies; preferred_gcc_version=v"9",
               julia_compat="1.6")
