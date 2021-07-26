# build several GAP binaries, one for each Julia version 1.6/1.7/...
using Base.BinaryPlatforms
include("../common.jl")


supported = (
    #(v"1.6", v"1.6.0"),
    (v"1.7", v"1.7.0"),
    #(v"1.8", v"1.7.0"), # HACK: until we have libjulia v1.8, use libjulia 1.7.0
)

for (julia_version, libjulia_version) in supported
    platforms = configure(julia_version, libjulia_version)

    any(should_build_platform.(triplet.(platforms))) || continue

    # Dependencies that must be installed before this package can be built
    dependencies = [
        Dependency("GMP_jll", compat="6.2.0"),
        Dependency("Readline_jll", compat="8.1.1"),
        Dependency("Zlib_jll"),
        BuildDependency(PackageSpec(name="libjulia_jll", version=libjulia_version)),
    ]

    # Build the tarballs.
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                   preferred_gcc_version=v"7", init_block=init_block, julia_compat="1.6")
end
