# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using Base.BinaryPlatforms
include("../common.jl")

gap_version = v"400.1191.001"
gap_lib_version = v"400.1191.000"
name = "JuliaInterface"
upstream_version = v"0.7.0" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

julia_versions = [v"1.6.0", v"1.7.0", v"1.8.0"]

# Collection of sources required to build libsingular-julia
sources = [
    GitSource("https://github.com/oscar-system/GAP.jl", "02de69a677054e4bad52fe1bc612071d1aeeb18a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd GAP.jl/pkg/JuliaInterface
./configure --with-gaproot=${prefix}/share/gap
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap/
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
