# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "norMD"
version = v"1.3.0"

# This script installs norMD (normalized Mean Distance) version 1.3, provided by the AQUA suite.
# norMD is a statistical metric used to assess the quality of multiple sequence alignments (MSAs).
# The `normd` program calculates the overall norMD score for an entire multiple sequence alignment.
#
# Usage example:
# - `normd aln_file`: Calculates the norMD score for the specified alignment file.
#
# If you use this tool, please cite the following references:
# - Thompson, J. D., Plewniak, F., Ripp, R., Thierry, J. C., & Poch, O. (2001). Towards a reliable objective function for multiple sequence alignments. Journal of molecular biology, 314(4), 937-951.
# - Muller, J., Creevey, C. J., Thompson, J. D., Arendt, D., & Bork, P. (2010). AQUA: automated quality improvement for multiple sequence alignments. Bioinformatics, 26(2), 263-265.

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.bork.embl.de/Docu/AQUA/latest/norMD1_3.tar.gz", "24ba32425640ae6288d59ca2bf5820dd85616132fe6a05337d849035184c660d"),
    FileSource("https://www.bork.embl.de/Docu/AQUA/latest/License.txt", "ddb9db7630752f8fdc6898f7c99a99eaeeac5213627ecb093df9c82f56175dc7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd normd_noexpat/
sed -i '/#include "score.h"/a#include <string.h>' init.c
make
mkdir ${bindir}
cp normd ${bindir}/
"""
# NOTE: Only the normd executable is installed.
# The programs normd_subaln, normd_range, normd_sw, normd_aln, and normd_aln1 are built but not installed.

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("normd", :normd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
