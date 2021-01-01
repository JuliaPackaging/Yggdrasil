using BinaryBuilder

name = "kubectl"
version = v"1.20.0"

sources = [
    FileSource("https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl", "a5895007f331f08d2e082eb12458764949559f30bcc5beae26c38f3e2724262c"; filename="x86_64-linux-gnu-kubectl"),
    FileSource("https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/darwin/amd64/kubectl", "82046a4abb056005edec097a42cc3bb55d1edd562d6f6f38c07318603fcd9fca"; filename="x86_64-apple-darwin14-kubectl"),
    FileSource("https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/windows/amd64/kubectl.exe", "ee7be8e93349fb0fd1db7f5cdb5985f5698cef69b7b7be012fc0e6bed06b254d"; filename="x86_64-w64-mingw32-kubectl"),
    FileSource("https://www.apache.org/licenses/LICENSE-2.0.txt", "cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30"; filename="LICENSE.txt")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${bindir}

install_license LICENSE.txt

mv "${target}-kubectl" "${bindir}/kubectl${exeext}"
chmod 755 "${bindir}/kubectl${exeext}"

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("kubectl", :kubectl),
]

dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
