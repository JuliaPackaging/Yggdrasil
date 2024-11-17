name = "LAPACK"

include("../common.jl")

script = lapack_script(lapack32=false)

products = [
    LibraryProduct("liblapack", :liblapack),
]

# Building ILP64 LAPACK on aarch64 linux runs into internal compiler errors with
# GCC ≤ 7 (=> libgfortran ≤ 4).
#filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libgfortran_version(p) ≤ v"4"), platforms)

append!(dependencies,
        [Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0")])

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.9", preferred_gcc_version=v"8")

# Build Trigger: 3
