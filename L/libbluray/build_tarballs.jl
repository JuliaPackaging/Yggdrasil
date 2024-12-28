# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libbluray"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://code.videolan.org/videolan/libbluray/-/archive/1.3.0/libbluray-1.3.0.tar.gz", "b305e453f8c6c409465a2d970857ff47bddaa0906486d66b4b8c725a404bbc69")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libbluray-*
apk add apache-ant
./bootstrap 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-bdjava-jar
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms =  filter!(!Sys.iswindows, supported_platforms())
# Remove this when we build a newer version for which we can target the former
# experimental platforms
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64") && arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libbluray", :libbluray),
    ExecutableProduct("bd_list_titles", :bd_list_titles),
    ExecutableProduct("bd_splice", :bd_splice),
    ExecutableProduct("bd_info", :bd_info)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
    Dependency(PackageSpec(name="FreeType2_jll", uuid="d7e528f0-a631-5988-bf34-fe36492bcfd7"); compat="2.10.4")
    Dependency(PackageSpec(name="Fontconfig_jll", uuid="a3f928ae-7b40-5064-980b-68af3947d34b"))
    Dependency(PackageSpec(name="libudfread_jll", uuid="037e6697-03b9-52b7-b841-7aee0d773eb5"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
