version = v"19.1.4"

include("../common.jl")

name, version, sources, script, platforms, products, dependencies =
    configure(version; experimental=true)

# The runtimes build links with `-nostdlib++`, which the riscv64 GCC doesn't accept.
# 19.1.4+0 had no riscv64 build either.
filter!(p -> arch(p) != "riscv64", platforms)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", preferred_llvm_version=v"18", julia_compat="1.12")

# Build trigger: 1
