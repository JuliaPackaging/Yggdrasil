# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
import Pkg: PackageSpec
import Pkg.Types: VersionSpec

name = "libpolymake_julia"
upstream_version = v"0.4.1"
version = VersionNumber(upstream_version.major, upstream_version.minor, upstream_version.patch * 100 + 10 + julia_version.minor)

# Collection of sources required to build libpolymake_julia
sources = [
    ArchiveSource("https://github.com/oscar-system/libpolymake-julia/archive/v$(upstream_version).tar.gz",
                  "f7733a8eb2b2e75d63db6cb6b035b9fae24ce7f6c2992253a3df0529a914ad37"),
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
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("polymake_run_script", :polymake_run_script),
    LibraryProduct("libpolymake_julia", :libpolymake_julia),
    FileProduct("share/libpolymake_julia/type_translator.jl",:type_translator),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
    BuildDependency(PackageSpec(name="GMP_jll", version=v"6.1.2")),
    BuildDependency(PackageSpec(name="MPFR_jll", version=v"4.0.2")),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("libcxxwrap_julia_jll", VersionNumber(0, 8, julia_version.minor)),
    Dependency("polymake_jll", compat = "~400.400.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8",
    julia_compat = "$(julia_version.major).$(julia_version.minor)")
