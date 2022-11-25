# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using Base.BinaryPlatforms
include("../common.jl")

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
using Pkg
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

gap_version = v"400.1200.101"
gap_lib_version = v"400.1201.100"
name = "JuliaInterface"
upstream_version = v"0.8.2" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.1" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]

# Collection of sources required to build this JLL
sources = [
    GitSource("https://github.com/oscar-system/GAP.jl", "62c1e9aedc4408c8f57ea2a9df8ce980a9c41d31"),
]

# Bash recipe for building across all platforms
script = raw"""
cd GAP.jl/pkg/JuliaInterface
./configure --with-gaproot=${prefix}/lib/gap
make -j${nproc} CFLAGS="-I${includedir} -I${includedir}/julia" LDFLAGS="-ljulia"

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

# copy the sources, too, so that we can later compare them
cp -r src ${prefix}/

install_license ../../LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)

# expand julia platforms
julia_platforms = []
for p in platforms
    for jv in julia_versions
        if jv == v"1.6.3" && Sys.isapple(p) && arch(p) == "aarch64"
            continue
        end
        p = deepcopy(p)
        BinaryPlatforms.add_tag!(p.tags, "julia_version", string(jv))
        push!(julia_platforms, p)
    end
end

push!(dependencies, BuildDependency("libjulia_jll"))

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/JuliaInterface.so", :JuliaInterface),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, julia_platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")


