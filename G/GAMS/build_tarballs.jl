# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GAMS"
version = v"48.6.1"

url_prefix = "https://d37drm4t2jghv5.cloudfront.net/distributions/$version"

# Collection of sources required to build micromamba
sources = [
    FileSource("$url_prefix/linux/linux_x64_64_sfx.exe",
        "f6f0cbc085808a418d2d55d2f9744002a8139c0afdb20020d0465b4cbaafb9a2",
        filename="linux_x64_64_sfx.exe"),
    FileSource("https://www.gams.com/GAMS_EULA.pdf",
        "213a684e5607ece92513075e3419cdd8ae5c6f8947e394fe178df0826a9f7229",
        filename="GAMS_EULA.pdf"),
]

# Bash recipe for building across all platforms
script = raw"""
# The file is self-extracting
cd $WORKSPACE/srcdir
chmod +x linux_x64_64_sfx.exe
./linux_x64_64_sfx.exe

# install
mkdir -p "${bindir}"
cp -a gams*_sfx/* "${bindir}"

# install the license
install_license GAMS_EULA.pdf
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
]

# The products that we will ensure are always built
const S = Symbol
executables = (
    # :apilib,
    # :baron,
    # S("connectdriver.py"),
    # :CPPMEX,
    # :csv2gdx,
    # :datalib,
    # :decisc,
    # :decism,
    # :emplib,
    # :endecrypt,
    # :finlib,
    # :gams,
    # :gamsconnect,
    # :gamsgetkey,
    # :gamsinst,
    # :gamskeep,
    # :gamslib,
    # :gamspermset,
    # :gamsprobe,
    # :gamstool,
    :gdx2sqlite,
    # :gdx2veda,
    # :gdxcopy,
    # :gdxdiff,
    # :gdxdiffold,
    :gdxdump,
    # :gdxdumpold,
    # :gdxmerge,
    # :gdxmergeold,
    # :gdxunittests,
    # S("gevgrid.run"),
    # S("gmsba_us.run"),
    # S("gmsck_us.run"),
    # S("gmscvnus.run"),
    # S("gmsdecus.run"),
    # S("gmsdemus.run"),
    # S("gmsdi_us.run"),
    # S("gmsecpus.run"),
    # S("gmsgenus.run"),
    # S("gmsge_us.run"),
    # S("gmsgewus.run"),
    # S("gmsgrid.run"),
    # S("gmsja_us.run"),
    # S("gmske_us.run"),
    # S("gmsmceus.run"),
    # S("gmsptnus.run"),
    # S("gmssb_us.run"),
    # :gmsunpack,
    # :gmsunzip,
    # S("gmsxitus.run"),
    # :gmszip,
    # :grbgetkey,
    # :grbprobe,
    # S("model2tex.py"),
    # S("model2tex.sh"),
    # :mps2gms,
    # :noalib,
    # :psoptlib,
    # :scenred2,
    # :sqlite3,
    # :testlib,
    # S("tooldriver.py"),
    # :workfile2yaml,
)
products = Product[
    [ExecutableProduct(string(sym), sym) for sym in executables]...
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.11", lazy_artifacts=true)
