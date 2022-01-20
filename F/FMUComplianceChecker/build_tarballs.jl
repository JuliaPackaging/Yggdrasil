# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FMUComplianceChecker"
version = v"2.0.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/modelica-tools/FMUComplianceChecker/archive/refs/tags/$(version).tar.gz", "361a1995fe498f5399092cff119c78a4500abbb7b9ca8c77d48a7de72c294f59")
]

# Bash recipe for building across all platforms
script = raw"""
apk add subversion

cd $WORKSPACE/srcdir
mkdir ${bindir}/

cd FMUComplianceChecker-*/

mkdir build; cd build
cmake ..
make install test

if [[ "${target}" == *linux* ]]; then
    mv ../install/fmuCheck.linux64 ${bindir}/fmuCheck
fi

if [[ "${target}" == *mingw* ]]; then
    mv ../install/fmuCheck.win64.exe ${bindir}/fmuCheck.exe
fi

chmod +x ${bindir}/*

LIC_DIR="${prefix}/share/licenses/${SRC_NAME}"
mkdir -p "${LIC_DIR}"
mv "../LICENCE" "${LIC_DIR}/LICENSE"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"; ),
    Platform("x86_64", "linux"; libc = "glibc"),
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("fmuCheck", :libFMUCheck)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
