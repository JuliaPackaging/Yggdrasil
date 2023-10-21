using BinaryBuilder

# Collection of pre-build edfplusdcnv binaries
name = "edfplusdcnv"
edfplusdcnv_ver = "1.0.0"
version = VersionNumber(edfplusdcnv_ver)

sources = [
    ArchiveSource("https://www.teuniz.net/edfplusd-converter/edfplusdcnv_100.tar.gz", "eeb6033a2f21dc052852e3dd779da7d368f65d88e45b7e40fa14f4bb514e62b9"; unpack_target = "x86_64-linux-gnu"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/
install -Dvm 755 edfplusdcnv_*/edfplusdcnv "${bindir}/edfplusdcnv"
install_license ${bindir}/README
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("edfplusdcnv", :edfplusdcnv),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
