# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "R2R"
version = v"1.0.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/projects/weinberg-r2r/files/R2R-1.0.6.tgz",
                  "1ba8f51db92866ebe1aeb3c056f17489bceefe2f67c5c0bbdfbddc0eee17743d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/R2R-*/

atomic_patch -p1 ../patches/fix-ptr-to-int-on-windows-64bit.patch
atomic_patch -p1 ../patches/isfinite.patch
atomic_patch -p1 ../patches/fix-format-strings.patch

update_configure_scripts --reconf
export CXXFLAGS="-std=c++11"
./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-nlopt

make -j${nproc}
make install

# install manual
# mkdir "${prefix}/doc"
# cp R2R-manual.pdf "${prefix}/doc"

# install demos
# cp -r demo/ "${prefix}"

install_license r2r-gpl-text.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("r2r", :r2r),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"7")
