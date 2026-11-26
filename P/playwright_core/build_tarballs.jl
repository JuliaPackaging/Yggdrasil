using BinaryBuilder, Pkg

name = "playwright_core"
version = v"1.65.1"
libwebp_commit = "3757b8afeb54e305eaef18502812a9a88b7ed662"

sources = [
    GitSource("https://github.com/microsoft/playwright.git",
              "bbd948344ea9a60bf1e6f125c02ca99b2b51593b"; tag="v$(version)"),
    # Playwright pins this unreleased commit for the Emscripten SIMD fixes.
    GitSource("https://github.com/webmproject/libwebp.git", libwebp_commit),
    GitSource("https://github.com/emscripten-core/emscripten.git",
              "7a2d97d627ff4945eae28847ce0387ac52b92c09"; tag="6.0.2"),
]

script = "export LIBWEBP_COMMIT=$(libwebp_commit)\n" * raw"""
cd "${WORKSPACE}/srcdir"
# Node.js needs pthread_getname_np, which the sandbox's musl lacks.
install -Dvm 755 "${host_bindir}/node" "${WORKSPACE}/host-tools/node"
patchelf --set-interpreter "${host_prefix}/lib/ld-musl-${MACHTYPE%%-*}.so.1" "${WORKSPACE}/host-tools/node"
export PATH="${WORKSPACE}/srcdir/emscripten:${WORKSPACE}/host-tools:${host_bindir}:${PATH}"
export EM_CONFIG="${WORKSPACE}/srcdir/.emscripten"
cat > "${EM_CONFIG}" <<EOF
LLVM_ROOT = "${host_prefix}/tools"
BINARYEN_ROOT = "${host_prefix}"
NODE_JS = ["${WORKSPACE}/host-tools/node"]
EOF

# Skip dependency lifecycle hooks that fetch browser and Electron binaries.
export npm_config_ignore_scripts=true
export npm_config_audit=false
export npm_config_fund=false
cd emscripten
python3 bootstrap.py

cd "${WORKSPACE}/srcdir"
# The upstream script reuses a local checkout with this name.
ln -s libwebp "libwebp-${LIBWEBP_COMMIT}"
cd playwright
WORK="${WORKSPACE}/srcdir" bash utils/libwebp-wasm/build.sh

npm ci
npm run build
install -vm 644 LICENSE NOTICE packages/playwright-core/
node utils/pack_package.js playwright-core "${WORKSPACE}/playwright-core.tgz"

package_dir="${prefix}/share/playwright-core"
mkdir -pv "${package_dir}"
tar -xzf "${WORKSPACE}/playwright-core.tgz" --strip-components=1 -C "${package_dir}"
cd "${package_dir}"
install_license LICENSE NOTICE ThirdPartyNotices.txt lib/*.LICENSE
node cli.js --version
node -e 'new WebAssembly.Module(require("node:fs").readFileSync("lib/webp_codec.wasm"))'
"""

platforms = supported_platforms()
# NodeJS_24_jll has no 32-bit or FreeBSD artifacts.
filter!(p -> nbits(p) == 64, platforms)
filter!(!Sys.isfreebsd, platforms)
# Upstream Node.js does not publish a RISC-V binary.
filter!(p -> arch(p) != "riscv64", platforms)
# The community musl builds of Node.js are available only for x86_64 and aarch64.
filter!(p -> libc(p) != "musl" || arch(p) in ("x86_64", "aarch64"), platforms)

# Match the Linux artifact tags used by NodeJS_24_jll.
for p in filter(Sys.islinux, platforms)
    p["cxxstring_abi"] = "cxx11"
end

products = [
    FileProduct("share/playwright-core/cli.js", :cli),
    FileProduct("share/playwright-core/lib/webp_codec.wasm", :webp_wasm),
]

dependencies = [
    RuntimeDependency("NodeJS_24_jll"; compat="24.18.0"),
    HostBuildDependency(PackageSpec(name="NodeJS_24_jll", version="24.18.0")),
    HostBuildDependency(PackageSpec(name="Musl_jll", version="1.2.6")),
    HostBuildDependency(PackageSpec(name="Python_jll", version="3.12.14")),
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version="23.1.1")),
    HostBuildDependency(PackageSpec(name="Binaryen_jll", version="0.130.0")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
