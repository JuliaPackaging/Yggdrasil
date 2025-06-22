# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AM"
version = v"13.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://zenodo.org/records/8161261/files/am-13.0.tgz", "1298257dc6a1f50aabc495bc7055e27975f03b67bb28e8f59f812ff39ddd3a36")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/am-13.0/src/
make -j ${nproc} am
install -Dvm 755 "am" "${bindir}/am${exeext}"
install_license ./LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("am", :am)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
