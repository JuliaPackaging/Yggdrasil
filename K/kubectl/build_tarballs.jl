using BinaryBuilder

name = "kubectl"
version = v"1.28.10"

# Release history can be found at: https://kubernetes.io/releases/
# Links to downloads can found at: https://kubernetes.io/docs/tasks/tools/
sources = [
    FileSource("https://dl.k8s.io/release/v$(version)/bin/linux/amd64/kubectl", "389c17a9700a4b01ebb055e39b8bc0886330497440dde004b5ed90f2a3a028db"; filename="x86_64-linux-gnu-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/linux/arm64/kubectl", "e659d23d442c2706debe5b96742326c0a1e1d7b5c695a9fe7dfe8ea7402caee8"; filename="aarch64-linux-gnu-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/darwin/amd64/kubectl", "426e1cdfe990b6f0e26d3b5243e079650cc65d6b4b5374824197c5d471f99cff"; filename="x86_64-apple-darwin14-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/darwin/arm64/kubectl", "da88c27eeab82512f9a23c6d80a9c6cc933d3514d3cd4fb215c8b57868a78195"; filename="aarch64-apple-darwin20-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/windows/amd64/kubectl.exe", "eddfbb875a7458a474b3b9ed089369baa8a782b9921be01ecb8abd4e9f1097d9"; filename="x86_64-w64-mingw32-kubectl"),
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
