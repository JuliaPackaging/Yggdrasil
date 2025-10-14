# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using Base.BinaryPlatforms
include("../common.jl")

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
using Pkg
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

gap_version = v"400.1500.0"
name = "JuliaInterface"
upstream_version = "0.16.0" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    GitSource("https://github.com/oscar-system/GAP.jl", "43ec515a9c5e8f087e32c87e5412c600b8329a85"),
]

# Bash recipe for building across all platforms
script = raw"""
cd GAP.jl/pkg/JuliaInterface
./configure --with-gaproot=${prefix}/lib/gap
make CFLAGS="-I${includedir} -I${includedir}/julia" LDFLAGS="-ljulia -lgap" V=1

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

# copy the sources, too, so that we can later compare them
cp -r src ${prefix}/

install_license ../../LICENSE
"""

name = gap_pkg_name(name)
# dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms(expand_julia_versions=true)

# Unlike other GAP_pkg_* JLLs, we do *not* set a compat bound for GAP_jll and
# GAP_lib_jll here. Instead GAP.jl is expected to make sure that it uses right
# combination of those JLLs with GAP_pkg_juliainterface. This decoupling is
# important for smooth upgrades, since GAP.jl can in principle work with newer
# GAP_jll versions by transparently building a fresh version of the code in
# GAP_pkg_juliainterface, and ignoring the code in that JLL. But this is
# thwarted if GAP_pkg_juliainterface has an explicit dependency on the old
# GAP_jll.
#
# The only downside is that there is a risk of using a bad combination, but
# that's a small risk, usually immediately detected in CI test, and fixing it
# is easy as it only requires a change to GAP.jl, not to any JLLs.
dependencies = [
    Dependency("GAP_jll", gap_version),
    BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.20")),
]

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/JuliaInterface.so", :JuliaInterface),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1
