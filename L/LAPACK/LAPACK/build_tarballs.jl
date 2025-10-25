name = "LAPACK"

include("../common.jl")

script = lapack_script(lapack32=false)

products = [
    LibraryProduct("liblapack", :liblapack),
]

# Building ILP64 LAPACK on aarch64 linux runs into internal compiler errors with
# GCC ≤ 7 (=> libgfortran ≤ 4).
filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libgfortran_version(p) ≤ v"4"), platforms)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.12", preferred_gcc_version=v"6")

# Build Trigger: 11
