# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph_server"
version = v"0.3.18"

url_prefix = "https://github.com/oxigraph/oxigraph/releases/download/v$version/oxigraph_server_v$version"

# Collection of sources required to complete build
sources = [
    ArchiveSource("$(url_prefix)_aarch64_apple", "c0c2a64e7dc05cf9c24d4c29349baef583eead3e1f9984cdc2ac56a5beba9df7"; unpack_target = "arm64-apple-darwin"),
    ArchiveSource("$(url_prefix)_x86_64_apple", "c0c2a64e7dc05cf9c24d4c29349baef583eead3e1f9984cdc2ac56a5beba9df7"; unpack_target = "arm64-apple-darwin"),
    ArchiveSource("$(url_prefix)_aarch64_linux_gnu", "c0c2a64e7dc05cf9c24d4c29349baef583eead3e1f9984cdc2ac56a5beba9df7"; unpack_target = "arm64-apple-darwin"),
    ArchiveSource("$(url_prefix)_x86_64_linux_gnu", "c0c2a64e7dc05cf9c24d4c29349baef583eead3e1f9984cdc2ac56a5beba9df7"; unpack_target = "arm64-apple-darwin"),
    ArchiveSource("$(url_prefix)_x86_64_windows_msvc.exe", "c0c2a64e7dc05cf9c24d4c29349baef583eead3e1f9984cdc2ac56a5beba9df7"; unpack_target = "arm64-apple-darwin"),
    FileSource("https://raw.githubusercontent.com/oxigraph/oxigraph/v$version/LICENSE-MIT", "b98fbb37db5b23bc5cfdcd16793206a5a7120a7b01f75374e5e0888376e4691c")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
mv ${target}/oxigraph* ${target}/oxigraph_server${exeext}
cp ${target}/oxigraph_server${exeext} ${bindir}
chmod +x ${bindir}/*
install_license LICENSE-MIT.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("oxigraph_server", :oxigraph_server),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")
