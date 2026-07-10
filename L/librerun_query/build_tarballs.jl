using BinaryBuilder, Pkg

name = "librerun_query"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/BenChung/Rerun.jl.git", "2cbe6b14d1610981b4e4469cb99cca88376210f3"),
]

script = raw"""
cd $WORKSPACE/srcdir/Rerun*/native

export CC_$(echo $rust_host | sed "s/-/_/g")=$CC_BUILD
export ZSTD_SYS_USE_PKG_CONFIG=1
export PKG_CONFIG_ALLOW_CROSS=1
if [[ "${target}" == *musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

cargo build --release --target ${rust_target}
install -Dvm 755 -t "${libdir}" target/${rust_target}/release/*rerun_query*.${dlext}
install_license $WORKSPACE/srcdir/Rerun*/LICENSE
"""

platforms = supported_platforms()
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)   # i686-windows rust toolchain unusable
filter!(p -> arch(p) != "riscv64", platforms)                     # no rust toolchain
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

products = [
    LibraryProduct(["librerun_query", "rerun_query"], :librerun_query),
]

dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Zstd_jll"; compat="1.5.7")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.6", compilers = [:rust, :c],
    preferred_gcc_version = v"15.2.0", lock_microarchitecture = false)
