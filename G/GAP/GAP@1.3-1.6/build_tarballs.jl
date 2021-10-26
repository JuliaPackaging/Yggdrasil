# build a single GAP binary which supports Julia 1.3 - 1.5
include("../common.jl")

platforms = configure(v"1.5", v"1.5.3")

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", compat="6.1.2"),
    Dependency("Readline_jll", compat="8.0.4"),
    Dependency("Zlib_jll"),
    BuildDependency(PackageSpec(name="libjulia_jll", version=v"1.5.3")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", init_block=init_block)

