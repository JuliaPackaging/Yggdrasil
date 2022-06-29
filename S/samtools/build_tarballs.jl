# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "samtools"
version = v"1.14"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/samtools/samtools.git", "c29621d3ae075573fce83e229a5e02348d4e8147"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/samtools/
autoheader
autoconf -Wno-syntax
export CPPFLAGS="-I${includedir}"
if [[ "${target}" != *-darwin* ]]; then
    # Need to pass `-lcurl` because it's needed by libhts
    export LIBS="-lcurl"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true, exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("samtools", :samtools)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Ncurses_jll", uuid="68e3532b-a499-55ff-9963-d1c0c0748b3a"))
    Dependency(PackageSpec(name="htslib_jll", uuid="f06fe41e-9474-5571-8c61-5634d2b2700c"))
    # `MbedTLS_jll` is an indirect dependency through `htslib_jll` (-> `LibCURL_jll` ->
    # `MbedTLS_jll`).  For some reasons that aren't clear to me at the moment, we are
    # getting a version of `MbedTLS_jll` which doesn't match the one `LibCURL_jll` was
    # compiled with.
    BuildDependency(PackageSpec(; name="MbedTLS_jll", version="2.24"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
