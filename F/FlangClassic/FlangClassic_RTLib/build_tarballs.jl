name = "FlangClassic_RTLib"
version = v"13.0.0"

include("../common.jl")

push!(dependencies,
    HostBuildDependency("FlangClassic_jll")
)

products = Product[
    LibraryProduct("libflang", :libflang),
    LibraryProduct("libflangrti", :libflangrti),
    LibraryProduct("libompstub", :libompstub)
]

platforms = [
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "glibc"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, flang_script(false), platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"10", preferred_llvm_version=v"13", lock_microarchitecture=false)
