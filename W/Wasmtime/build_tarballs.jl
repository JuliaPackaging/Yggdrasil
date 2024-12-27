using BinaryBuilder

name = "Wasmtime"
version = v"24.0.0"

sources = [GitSource("https://github.com/bytecodealliance/wasmtime.git",
                     "6fc3d274c7994dad20c816ccc0739bf766b39a11")]

# Based on `wasmtime/ci/build-release-artifacts.sh
script = raw"""
cd ${WORKSPACE}/srcdir/wasmtime/

export CARGO_PROFILE_RELEASE_STRIP=debuginfo
export CARGO_PROFILE_RELEASE_PANIC=abort

if [[ "${target}" == armv* ]] || [[ "${target}" == aarch64-linux* ]]; then
    # The `ring` crate in the dependency tree requires this be set on ARM targets
    export CFLAGS="-D__ARM_ARCH"
fi

if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

cargo build \
    --release \
    --target ${rust_target} \
    -p wasmtime-cli \
    --features all-arch,component-model \
    --features run
install -Dvm 0755 \
    "target/${rust_target}/release/wasmtime${exeext}" \
    "${bindir}/wasmtime${exeext}"

mkdir -p target/c-api-build
cd target/c-api-build
cmake ../../crates/c-api \
    -DCMAKE_BUILD_TYPE=Release \
    -DWASMTIME_TARGET=${rust_target} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_INSTALL_LIBDIR=${libdir}
cmake --build . --target install

if [[ "${target}" == *-mingw* ]]; then
    mv "${libdir}/wasmtime.dll" "${libdir}/libwasmtime.dll"
fi
"""

platforms = supported_platforms(; exclude=(p -> !(arch(p) in ("x86_64", "aarch64"))))

# Filter aarch64 FreeBSD because no Rust toolchain is available there yet
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

# NOTE: Headers get installed too but we aren't explicitly listing them as `FileProduct`s
products = [LibraryProduct("libwasmtime", :libwasmtime),
            ExecutableProduct("wasmtime", :wasmtime)]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.6")
