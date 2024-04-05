name = "FlangClassic"
version = v"13.0.0"

include("../common.jl")

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("flang", :flang),
    ExecutableProduct("flang1", :flang1),
    ExecutableProduct("flang2", :flang2),
]

# We only build the compiler for musl. The rtlibs get built for all platforms in the RTLib jll
platforms = [
    Platform("x86_64", "linux"; libc = "musl"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, flang_script(true), platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"10", preferred_llvm_version=v"13", lock_microarchitecture=false)
