# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph_server"
version = v"0.3.22"

url_prefix = "https://github.com/oxigraph/oxigraph/releases/download/v$version/oxigraph_server_v$version"

# Collection of sources required to complete build
sources = [
    FileSource("$(url_prefix)_aarch64_apple", "eb257070e93c39569e906a4523c5ec3f9011d87b672206b5d77408da57b71e0a"; filename = "oxigraph_server-aarch64-apple-darwin20"),
    FileSource("$(url_prefix)_x86_64_apple", "bc7967199cd70945e95f649511ccfda78cb9f3b3a14931d73210207741be2ae3"; filename = "oxigraph_server-x86_64-apple-darwin14"),
    FileSource("$(url_prefix)_aarch64_linux_gnu", "727043118272953123bf3bd9835a5d9ecf394b72f603fd745f155caa1f61b2ee"; filename = "oxigraph_server-aarch64-linux-gnu"),
    FileSource("$(url_prefix)_x86_64_linux_gnu", "728f34d92fbb73e9b42655b6edd47a061e638f7e6e621e7f123772d41048942a"; filename = "oxigraph_server-x86_64-linux-gnu"),
    FileSource("$(url_prefix)_x86_64_windows_msvc.exe", "eb8499e1a510ae904511e585e233f2d81bbf5ee70a4949a75102e57901903e69"; filename = "oxigraph_server-x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/oxigraph/oxigraph/v$version/LICENSE-MIT", "1f4f6736adc52ebfda18bb84947e0ef492bd86a408c0e83872efb75ed5e02838"; filename = "LICENSE.txt")
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
