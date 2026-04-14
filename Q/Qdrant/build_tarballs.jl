using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "Qdrant"
qdrant_ver = "1.17.1"
version = VersionNumber(qdrant_ver)

url_prefix = "https://github.com/qdrant/qdrant/releases/download/v$(qdrant_ver)/qdrant-"
sources = [
    ArchiveSource("$(url_prefix)x86_64-unknown-linux-musl.tar.gz", "4028d5e753de53bda82fa487df25353f668e785c3dfff66dfa636e2203a82b3a"; unpack_target="x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)x86_64-unknown-linux-gnu.tar.gz", "318a3b1c548161ad476f9ff70b654787a20fc46685e3e1c2b7dd88b363ef3d58"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)aarch64-unknown-linux-musl.tar.gz", "9347a4db839f53fe123cc775bd87e4dd02f6c2750783bea02ea4fcae9c923164"; unpack_target="aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)x86_64-apple-darwin.tar.gz", "d7308c504afa58eb4aa2bd0c655252c324aea04891ac079b6b8764b33fa7dc15"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)aarch64-apple-darwin.tar.gz", "adf795d7c2ac9d93677517fd58b119e9bb5bc8fc5143ac9b581a6f8264def8da"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)x86_64-pc-windows-msvc.zip", "fe28df5993a9f9830b1e7290e2e341becf3c91366941b73b4322a05e4f91585c"; unpack_target="x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/qdrant/qdrant/refs/tags/v$(qdrant_ver)/LICENSE", "5fea605a17e4e927542d0031a7c82e557c89f13a0c6e44412920d5d2483afc48"),
    ]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
install -Dvm 755 "${target}/qdrant${exeext}" "${bindir}/qdrant${exeext}"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const P = Platform
platforms = [
    P("x86_64", "linux"),
    P("x86_64", "linux"; libc="musl"),
    P("aarch64", "linux"; libc="musl"),
    P("x86_64", "macos"),
    P("aarch64", "macos"),
    P("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("qdrant", :qdrant),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
