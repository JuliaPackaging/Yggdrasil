# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, Base.BinaryPlatforms

name = "rtmidi"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/thestk/rtmidi.git", "6e4e763a19860c17784992ff3170704ba73c10b7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/rtmidi/

# Autotools doesn't add `${includedir}` as an include directory on some platforms, for some reason
export CPPFLAGS="-I${includedir}"

./autogen.sh --prefix=${prefix} --build=${MACHTYPE} --host=${target}
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))
    
# Apparently there are no known MIDI backends for FreeBSD :(
platforms = filter(p -> os(p) != "freebsd", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("librtmidi", :rtmidi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
