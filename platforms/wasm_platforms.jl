# The WebAssembly platforms, once BinaryBuilder has them (route B). Until then, see platforms/wasm.jl.
# wasm32-wasip1 is the platform every toolchain supports; wasm64 has no WASI sysroot yet.
wasm_platforms() = [Platform("wasm32", "wasi"; os_version = v"1")]
