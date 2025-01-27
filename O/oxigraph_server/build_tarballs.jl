# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph_server"
version = v"0.4.7"

url_prefix = "https://github.com/oxigraph/oxigraph/releases/download/v$version/oxigraph_v$version"

# Collection of sources required to complete build
sources = [
    FileSource("$(url_prefix)_aarch64_apple", "9051a821f1f7d1bafeb622b44293369fd68c70425141ef56bddd69f4b3ea1a67"; filename = "oxigraph_server-aarch64-apple-darwin20"),
    FileSource("$(url_prefix)_x86_64_apple", "3bc3c89d2ea1d3ad45e4e9d4c5c86ffc8be8266a930be767db98db0b5838ffc5"; filename = "oxigraph_server-x86_64-apple-darwin14"),
    FileSource("$(url_prefix)_aarch64_linux_gnu", "998ca76d3c2c25d02404fe8e808f8cab6119ee894653d48958fd8a01e8cfb5e7"; filename = "oxigraph_server-aarch64-linux-gnu"),
    FileSource("$(url_prefix)_x86_64_linux_gnu", "d34c1011339ad9337225f64943dbca8f439b495041ba38a1d40f440dd1d28a4b"; filename = "oxigraph_server-x86_64-linux-gnu"),
    FileSource("$(url_prefix)_x86_64_windows_msvc.exe", "eb8499e1a510ae904511e585e233f2d81bbf5ee70a4949a75102e57901903e69"; filename = "oxigraph_server-x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/oxigraph/oxigraph/v$version/LICENSE-MIT", "000d2aa6b11092d068edf2586542073f92584eb65e0018f59b611da4470f454b"; filename = "LICENSE.txt")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
install -Dvm 755 "oxigraph_server-${target}" "${bindir}/oxigraph_server${exeext}"
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> (arch(p) == "powerpc64le" || Sys.isfreebsd(p) || (Sys.islinux(p) && libc(p) == "musl") || nbits(p) != 64))
platforms = expand_cxxstring_abis(platforms)

# Binaries are built upstream using GCC v9+, skip CXX03 string ABI
platforms = filter(x -> cxxstring_abi(x) != "cxx03", platforms)

# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("oxigraph_server", :oxigraph_server),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")
