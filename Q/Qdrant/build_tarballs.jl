using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "Qdrant"
qdrant_ver = "1.15.3"
version = VersionNumber(qdrant_ver)

url_prefix = "https://github.com/qdrant/qdrant/releases/download/v$(qdrant_ver)/qdrant-"
sources = [
    ArchiveSource("$(url_prefix)x86_64-unknown-linux-musl.tar.gz", "9393a79ad9c2e1e07efa1612d091cc4812cdfebfda1a6186e6925ae7c0a9fe0e"; unpack_target="x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)x86_64-unknown-linux-gnu.tar.gz", "26d7b7fa397a8f936721038b99f6c6557ea7540768e902db97dfc6f83f72eb69"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)aarch64-unknown-linux-musl.tar.gz", "b9ac8d2989904c2b9d44ac396c64241d5b97733a32f23c5f52667cf4ef67b072"; unpack_target="aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)x86_64-apple-darwin.tar.gz", "9ddaa9dd670431b15a42f868582fffd1291f3898d28c9c7185c357e62f393e1b"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)aarch64-apple-darwin.tar.gz", "c8404af1727aab1ccb0a7dd4c644091954d056ec4e4ec898987fc0647f5128c6"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)x86_64-pc-windows-msvc.zip", "5049d33ed8f0640b3f80feea08c55fcb5cd155f75ed91c5e5e40b2e90570a62b"; unpack_target="x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/qdrant/qdrant/refs/tags/v$(qdrant_ver)/LICENSE", "c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4"),
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
