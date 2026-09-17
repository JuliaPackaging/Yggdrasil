using BinaryBuilder, Pkg

# Collection of pre-built qdrant binaries
name = "Qdrant"
qdrant_ver = "1.18.3"
version = VersionNumber(qdrant_ver)

url_prefix = "https://github.com/qdrant/qdrant/releases/download/v$(qdrant_ver)/qdrant-"
sources = [
    ArchiveSource("$(url_prefix)x86_64-unknown-linux-musl.tar.gz", "b4faedcdf8c9577bf1c8f2ab9b454636b87e056c116c99d49bd4f9fb2e634285"; unpack_target="x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)x86_64-unknown-linux-gnu.tar.gz", "60663a254cf421dba4db45710872895cd3a714fe1e6978f7927923b5cfae4718"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)aarch64-unknown-linux-musl.tar.gz", "1e738b45f90935c383b4076c30f377f390964cb5962b5bff24439812d157dc24"; unpack_target="aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)x86_64-apple-darwin.tar.gz", "45bdd4642e7f25611e9cd74f9f91482b27c5376840cd8dc476da67b87abe25a6"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)aarch64-apple-darwin.tar.gz", "0cb040a261035c316779bd7b4cca2e6ab39faf62640d6918bbbe320e2a9a6547"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)x86_64-pc-windows-msvc.zip", "984619bbd4032ace578656174c465c5d6b71d1267ecad5b7b4c21cc6549ca833"; unpack_target="x86_64-w64-mingw32"),
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
