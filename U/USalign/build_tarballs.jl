# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "USalign"
version = v"2022.9.24"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pylelab/USalign.git", "944c6a81c453b43d173d8f18ff3197d59650c2cc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd USalign/
# Remove the -ffast-math flag from the suggested g++ command as required by BinaryBuilder.
sed -i 's/-ffast-math//g' Makefile
# The following sed statements are needed to support Linux powerpc64le {libc=glibc}.
if [[ "${target}" == powerpc64le* ]]; then
    sed -i 's/\bA0\b/A0_var/g' TMalign.h;
    sed -i 's/\bB0\b/B0_var/g' TMalign.h;
    sed -i 's/\bC0\b/C0_var/g' TMalign.h;
    sed -i 's/\bD0\b/D0_var/g' TMalign.h;
fi
# Remove the -static flag to support macOS aarch64 and x86_64.
if [[ "${target}" == *-apple-darwin* ]]; then
    sed -i 's/-static//g' Makefile;
fi
# Add a dummy pstream.h to allow compilation on Windows.
if [[ "${target}" == *-mingw* ]]; then
    echo -e '#ifndef PSTREAM_H\n' \
    '#define PSTREAM_H\n' \
    '\n#include <iostream>\n' \
    '\nnamespace redi {\n' \
    '    class ipstream {\n' \
    '    public:\n' \
    '        ipstream() {\n' \
    '            std::cout << "POSIX is not supported on Linux, so this program cannot deal with gzipped files on this platform.\\n";\n' \
    '        }\n' \
    '\n        void open(const std::string&) {\n' \
    '            std::cout << "ipstream::open is not supported on this platform.\\n";\n' \
    '        }\n' \
    '        bool good() const { return false; }\n' \
    '        void close() {}\n' \
    '        friend ipstream& getline(ipstream& is, std::string& str) { return is; }\n' \
    '    };\n' \
    '}\n' \
    '\n#endif // PSTREAM_H' > pstream.h;
    # Fix the EXIT_SUCCESS not declared error
    sed -i '1i#include <cstdlib>' pdbAtomName.cpp
fi
make
PROGRAM=$(grep "PROGRAM=" Makefile | cut -d '=' -f2)
for prog in $PROGRAM; do
    cp $prog ${prefix}/;
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("TMscore", :TMscore),
    ExecutableProduct("cif2pdb", :cif2pdb),
    ExecutableProduct("qTMclust", :qTMclust),
    ExecutableProduct("pdb2fasta", :pdb2fasta),
    ExecutableProduct("HwRMSD", :HwRMSD),
    ExecutableProduct("TMalign", :TMalign),
    ExecutableProduct("USalign", :USalign),
    ExecutableProduct("se", :se),
    ExecutableProduct("MMalign", :MMalign),
    ExecutableProduct("pdb2xyz", :pdb2xyz),
    ExecutableProduct("pdbAtomName", :pdbAtomName),
    ExecutableProduct("pdb2ss", :pdb2ss),
    ExecutableProduct("xyz_sfetch", :xyz_sfetch),
    ExecutableProduct("NWalign", :NWalign)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
