# build GAP binary for Julia 1.7 (and possibly beyond)
include("../common.jl")

platforms = configure(v"1.7", v"1.7.0")

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", compat="6.2.0"),
    Dependency("Readline_jll", compat="8.1.1"),
    Dependency("Zlib_jll"),
    BuildDependency(PackageSpec(name="libjulia_jll", version=v"1.7.0")),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", init_block=init_block, julia_compat="1.7")
