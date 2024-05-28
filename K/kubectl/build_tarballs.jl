using BinaryBuilder

name = "kubectl"
version = v"1.27.14"

# Release history can be found at: https://kubernetes.io/releases/
# Links to downloads can found at: https://kubernetes.io/docs/tasks/tools/
sources = [
    FileSource("https://dl.k8s.io/release/v$(version)/bin/linux/amd64/kubectl", "1d2431c68bb6dfa9de3cd40fd66d97a9ac73593c489f9467249eea43e9c16a1e"; filename="x86_64-linux-gnu-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/linux/arm64/kubectl", "29f3a1f520d929df38873c68dec73519c1e5e521140e01cf9d7701f7b5ffe4f3"; filename="aarch64-linux-gnu-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/darwin/amd64/kubectl", "f0dca5da8a5e9f06be7ae56dba08f1c4c3db8a2b3a3db553b7eeebaf726b854d"; filename="x86_64-apple-darwin14-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/darwin/arm64/kubectl", "8e1e4189b008eac3acc18594136429bf24676736402736e5cc72bd52a84aad9a"; filename="aarch64-apple-darwin20-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/windows/amd64/kubectl.exe", "26d74b2daae55373b220bf5da8b14e98a5acf2f3a9088df17887bea83f37e0bf"; filename="x86_64-w64-mingw32-kubectl"),
    FileSource("https://raw.githubusercontent.com/kubernetes/kubernetes/v$(version)/LICENSE", "cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
install_license LICENSE
install -Dvm 755 "${target}-kubectl" "${bindir}/kubectl${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("kubectl", :kubectl),
]

dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
