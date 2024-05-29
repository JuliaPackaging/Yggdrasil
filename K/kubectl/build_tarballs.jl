using BinaryBuilder

name = "kubectl"
version = v"1.29.5"

# Release history can be found at: https://kubernetes.io/releases/
# Links to downloads can found at: https://kubernetes.io/docs/tasks/tools/
sources = [
    FileSource("https://dl.k8s.io/release/v$(version)/bin/linux/amd64/kubectl", "603c8681fc0d8609c851f9cc58bcf55eeb97e2934896e858d0232aa8d1138366"; filename="x86_64-linux-gnu-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/linux/arm64/kubectl", "9ee9168def12ac6a6c0c6430e0f73175e756ed262db6040f8aa2121ad2c1f62e"; filename="aarch64-linux-gnu-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/darwin/amd64/kubectl", "395082ef84594ea4cb170d599056406ed2cf39555b53e92e0caee013c1ed5cdf"; filename="x86_64-apple-darwin14-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/darwin/arm64/kubectl", "23b09c126c0a0b71b58cc725a32cf84f1753242b3892dfd762511f2da6cce165"; filename="aarch64-apple-darwin20-kubectl"),
    FileSource("https://dl.k8s.io/release/v$(version)/bin/windows/amd64/kubectl.exe", "8de419ccecdde90172345e7d12a63de42c217d28768d84c2398d932b44d73489"; filename="x86_64-w64-mingw32-kubectl"),
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
