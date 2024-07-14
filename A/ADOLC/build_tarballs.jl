# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://discourse.julialang.org/t/binarybuilder-jl-cant-dlopen-because-of-libopenlibm-so/108486
# This build script needs to be run with julia 1.7

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "ADOLC"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/ADOL-C.git", "b7ea10536a1e452f7dd47a90ef8c8118ce3e8432"),
    GitSource("https://github.com/TimSiebert1/libadolccxx.git", "afab700737d7da313b6fb43e95b76bb1671a7085"),
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ADOL-C/
autoreconf -fi
./configure --enable-atrig-erf --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license LICENSE

cd ../libadolccxx/
cmake -DCMAKE_INSTALL_PREFIX=${prefix}\
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
      -DCMAKE_BUILD_TYPE=Release\
      -DADOLC_DIR=${prefix}\
      -DJulia_PREFIX=${prefix}\
      -B build .

cd build
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# See https://discourse.julialang.org/t/binarybuilder-jl-cant-dlopen-because-of-libopenlibm-so/108486
# It seems we need a separate build for each Julia version
include("../../L/libjulia/common.jl")

julia_versions=VersionNumber[v"1.9", v"1.10", v"1.11"]

platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# Current restriction:
# ADOLC does not compile with musl libc.
# Typical Error:
# /opt/aarch64-linux-musl/aarch64-linux-musl/include/c++/7.1.0/cstdlib:144:11: error: ‘::calloc’ has not been declared 
# Same for realloc and malloc.
filter!(p->  (libc(p)!="musl"), platforms)

products = [
    LibraryProduct("libadolc_wrap", :libadolc_wrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7");compat="0.13")
    BuildDependency(PackageSpec(name="libjulia_jll", uuid="5ad3ddd2-0711-543a-b040-befd59781bbf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"8", clang_use_lld=false)
