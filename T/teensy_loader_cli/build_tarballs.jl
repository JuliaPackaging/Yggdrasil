# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "teensy_loader_cli"
version_string = "2.2"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PaulStoffregen/teensy_loader_cli", "99082869db86f1f5ff7eef0d45262bc7e674f890")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/teensy_loader_cli
make -j${nprocs}
install -Dvm 755 "teensy_loader_cli${exeext}" "${bindir}/teensy_loader_cli${exeext}"
install_license gpl3.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)


# The products that we will ensure are always built
products = [
    ExecutableProduct("teensy_loader_cli", :teensy_loader_cli),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libusb_compat_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
