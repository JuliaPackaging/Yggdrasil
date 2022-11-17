using BinaryBuilder

name = "Tokei"
upstream_version = v"12.1.2"
version = VersionNumber(
    upstream_version.major,
    upstream_version.minor,
    upstream_version.patch * 100 + 0,
)

sources = [
    ArchiveSource("https://github.com/XAMPPRocky/tokei/archive/refs/tags/v$(upstream_version).tar.gz",
                  "81ef14ab8eaa70a68249a299f26f26eba22f342fb8e22fca463b08080f436e50"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/tokei*/
cargo build --release
install -D -m 755 "target/${rust_target}/release/tokei${exeext}" "${bindir}/tokei${exeext}"
install_license LICENCE-MIT LICENCE-APACHE
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("tokei", :tokei),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
