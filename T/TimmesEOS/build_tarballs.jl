# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TimmesEOS"
version = v"1"

# Collection of sources required to complete build
sources = [
    # BinaryBuilder cannot download `tbz` files, so we unpack it ourselves
    # ArchiveSource("https://cococubed.com/codes/eos/timmes.tbz",
    #               "e20c7d27e66c240486a3397a649c49673e33100284f0905cd6fa9893dbad30a9"),
    FileSource("https://cococubed.com/codes/eos/timmes.tbz",
               "e20c7d27e66c240486a3397a649c49673e33100284f0905cd6fa9893dbad30a9"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
tar xjf timmes.tbz
cd ${WORKSPACE}/srcdir/timmes
atomic_patch -p0 ${WORKSPACE}/srcdir/patches/nomain.patch
${FC} -O -fPIC -shared -o libeosfxt.${dlext} eosfxt.f90
install -Dvm 755 libeosfxt.${dlext} ${libdir}/libeosfxt.${dlext}


# The tarball does not include a license. The package author F. X.
# Timmes confirmed via email that this license is appropriate:
# "whatever i post on my website is free to use in any manner one
# wishes. attribution is nice, but not required."
install_license ${WORKSPACE}/srcdir/files/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libeosfxt", :libeosfxt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
