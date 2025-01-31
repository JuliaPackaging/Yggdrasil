# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Lingeling"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/arminbiere/lingeling.git", "89a167d0d2efe98d983c87b5b84175b40ea55842"),
    DirectorySource("./bundled")
    ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lingeling*
cp ../makefile .
sed -i '/#include *<stdlib.h>/a #include <stdint.h>' *.c
sed -i '/#include *<stdlib.h>/a #include <stdint.h>' *.h
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)
filter!(!Sys.isapple, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("lingeling", :lingeling),
    ExecutableProduct("plingeling", :plingeling),
    ExecutableProduct("ilingeling", :ilingeling),
    ExecutableProduct("treengeling", :treengeling),
    ExecutableProduct("lglmbt", :lglmbt),
    ExecutableProduct("lgluntrace", :lgluntrace),
    ExecutableProduct("lglddtrace", :lglddtrace),
    LibraryProduct("liblgl",:liblgl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")