using BinaryBuilder

name = "kubectl"
version = v"1.30.1"

# Release history can be found at: https://kubernetes.io/releases/
# Links to downloads can found at: https://kubernetes.io/docs/tasks/tools/
sources = [
    FileSource("https://dl.k8s.io/release/v$(version)/bin/linux/amd64/kubectl", "5b86f0b06e1a5ba6f8f00e2b01e8ed39407729c4990aeda961f83a586f975e8a"; filename="x86_64-linux-gnu-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/linux/arm64/kubectl", "d90446719b815e3abfe7b2c46ddf8b3fda17599f03ab370d6e47b1580c0e869e"; filename="aarch64-linux-gnu-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/darwin/amd64/kubectl", "eaefb69cf908b7473d2dce0ba894c956b7e1ad5a4987a96d68a279f5597bb22d"; filename="x86_64-apple-darwin14-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/darwin/arm64/kubectl", "55dec3c52702bd68488a5c1ab840b79ea9e73e4b9f597bcf75b201c55d0bd280"; filename="aarch64-apple-darwin20-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/windows/amd64/kubectl.exe", "f7391a2de0491caadedb5178ac2485cbf104189b2e0f3d6c577bd6ea1892898f"; filename="x86_64-w64-mingw32-kubectl"),
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
