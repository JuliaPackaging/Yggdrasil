# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
import Pkg: PackageSpec
import Pkg.Types: VersionSpec

name = "libpolymake_julia"
version = v"0.2.0"

# Collection of sources required to build libpolymake_julia
sources = [
    ArchiveSource("https://github.com/oscar-system/libpolymake-julia/archive/v$(version).tar.gz",
                  "2ad38e380ae52d9f1c72374fe785ab0253bad9bfd8eaa078da82eaed14f3e83c"),
]

# Bash recipe for building across all platforms
script = raw"""
# remove $libdir from LD_LIBRARY_PATH as this causes issues with perl
if [[ -n "$LD_LIBRARY_PATH" ]]; then
LD_LIBRARY_PATH=$(echo -n $LD_LIBRARY_PATH | sed -e "s|[:^]$libdir\w*|:|g")
fi

cmake libpolymake-j*/ -B build \
   -DJulia_PREFIX="$prefix" \
   -DCMAKE_INSTALL_PREFIX="$prefix" \
   -DCMAKE_FIND_ROOT_PATH="$prefix" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_BUILD_TYPE=Release

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license $WORKSPACE/srcdir/libpolymake-j*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "macos"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("polymake_run_script", :polymake_run_script),
    LibraryProduct("libpolymake_julia", :libpolymake_julia),
    FileProduct("share/libpolymake_julia/type_translator.jl",:type_translator),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency(PackageSpec(name="Julia_jll", version=v"1.4.1")),
    Dependency("libcxxwrap_julia_jll"),
    Dependency(PackageSpec(name="polymake_jll", version=VersionSpec("4.2.0-4.2"))),
    BuildDependency(PackageSpec(name="GMP_jll", version=v"6.1.2")),
    BuildDependency(PackageSpec(name="MPFR_jll", version=v"4.0.2")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
