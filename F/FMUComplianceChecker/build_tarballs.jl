# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FMUComplianceChecker"
version = v"2.0.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/modelica-tools/FMUComplianceChecker/archive/refs/heads/master.zip", "2f8f0754164c7c13f8de76f8ec3271899d4650a3ffe895c2e813cd0b46ae7cb7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
apk add subversion
mkdir ${bindir}/
cd FMUComplianceChecker-*/   
mkdir build; cd build
cmake ..
make install test
if [[ "${target}" == *linux* ]]; then     mv ../install/fmuCheck.linux64 ${bindir}/fmuCheck; fi
if [[ "${target}" == *mingw* ]]; then     mv ../install/fmuCheck.win64.exe ${bindir}/fmuCheck.exe; fi
chmod +x ${bindir}/*
LIC_DIR="${prefix}/share/licenses/${SRC_NAME}"
mkdir -p "${LIC_DIR}"
mv "../LICENSE" "${LIC_DIR}/LICENSE"
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
