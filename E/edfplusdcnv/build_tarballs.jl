using BinaryBuilder

# Collection of pre-build edfplusdcnv binaries
name = "edfplusdcnv"
edfplusdcnv_ver = "1.0.0"
version = VersionNumber(edfplusdcnv_ver)

sources = [
    ArchiveSource("https://www.teuniz.net/edfplusd-converter/edfplusdcnv_100.tar.gz", "7108cb34c10f56f960acaba499bab52d2403bf648f5c62d2e0c5e4469167427e"; unpack_target = "x86_64-linux-gnu"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
if [[ "${target}" != *-mingw* ]]; then
    subdir="bin/"
fi
cp ${target}/edfplusdcnv-*/${subdir}edfplusdcnv${exeext} ${bindir}
chmod +x ${bindir}/*
install_license README
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
