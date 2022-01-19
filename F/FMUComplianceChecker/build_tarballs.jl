# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FMUComplianceChecker"
version = v"2.0.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/modelica-tools/FMUComplianceChecker/releases/download/2.0.4/FMUChecker-2.0.4-linux64.zip", "02f6d1a175fe4c51d5840ef40fcd05ca7fb3ceec170d7825d9c946d75eae12eb"),
    ArchiveSource("https://github.com/modelica-tools/FMUComplianceChecker/releases/download/2.0.4/FMUChecker-2.0.4-win64.zip", "4932a46624a7ff84235bb49df7827c7b03684f6d67318ad272bd25548cb1dc8f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir ${bindir}/

if [[ "${target}" == *linux* ]]; then
    cd FMUChecker-2.0.4-linux64/
    mv ./fmuCheck.linux64 ${bindir}/fmuCheck
fi

if [[ "${target}" == *mingw* ]]; then
    cd FMUChecker-2.0.4-win64/
    mv ./fmuCheck.win64 ${bindir}/fmuCheck
fi

chmod +x ${bindir}/*
LIC_DIR="${prefix}/share/licenses/${SRC_NAME}"
mkdir -p "${LIC_DIR}"
mv "./LICENCE.md" "${LIC_DIR}/LICENSE.md"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"; ),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("fmuCheck", :libFMUCheck)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
