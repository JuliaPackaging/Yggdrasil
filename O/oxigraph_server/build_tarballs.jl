# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph_server"
version = v"0.3.18"

url_prefix = "https://github.com/oxigraph/oxigraph/releases/download/v$version/oxigraph_server_v$version"

# Collection of sources required to complete build
sources = [
    FileSource("$(url_prefix)_aarch64_apple", "c0c2a64e7dc05cf9c24d4c29349baef583eead3e1f9984cdc2ac56a5beba9df7"; filename = "oxigraph_server-arm64-apple-darwin"),
    FileSource("$(url_prefix)_x86_64_apple", "c5d1229d1011d30ed55226545abc9f9caa5f40d34cecf3b7d0e6964db516df6b"; filename = "oxigraph_server-x86_64-apple-darwin"),
    FileSource("$(url_prefix)_aarch64_linux_gnu", "be0ec046fe48adff38e08c235d8f3f56af8d278a0a672c7f438ab32504ecaa57"; filename = "oxigraph_server-aarch64-linux-gnu"),
    FileSource("$(url_prefix)_x86_64_linux_gnu", "1d62d475516f85dc8ab548ed0f8d25572186cbaf91cf43805d415d310045ea1e"; filename = "oxigraph_server-x86_64-linux-gnu"),
    FileSource("$(url_prefix)_x86_64_windows_msvc.exe", "232fab182aa30df0d004980b6d386fab3aabb89ec294386ee63df0f56622ccf1"; filename = "oxigraph_server-x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/oxigraph/oxigraph/v$version/LICENSE-MIT", "1f4f6736adc52ebfda18bb84947e0ef492bd86a408c0e83872efb75ed5e02838"; filename = "LICENSE.txt")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
mv oxigraph_server-${target} oxigraph_server${exeext}
cp oxigraph_server${exeext} ${bindir}
chmod +x ${bindir}/*
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> (Sys.isbsd(p) || libc(p) == "musl" || nbits(p) != 64 || arch(p) == "powerpc64le"))

# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("oxigraph_server", :oxigraph_server),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"5", lock_microarchitecture=false)
