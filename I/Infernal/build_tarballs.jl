# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Infernal"
version = v"1.1.4"

easel_version = v"0.48"
hmmer_version = v"3.3.2"

# Notes
# - Infernal requires SSE or VMX vector instructions,
#   VMX only on big-endian platforms (ppc64 not ppc64le)
# - ARM vector instruction support coming soon
# - build fails on windows
#   easel.c:39:20: fatal error: syslog.h: No such file or directory

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/EddyRivasLab/infernal/archive/refs/tags/infernal-$(version).tar.gz",
                  "311163c0a21a216e90862df81cd6c13811032076535e44fed4eabdcf45093fea"),
    ArchiveSource("https://github.com/EddyRivasLab/easel/archive/refs/tags/easel-$(easel_version.major).$(easel_version.minor).tar.gz",
                  "c5d055acbe88fa834e81424a15fc5fa54ac787e35f2ea72d4ffd9ea2c1aa29cf"),
    ArchiveSource("https://github.com/EddyRivasLab/hmmer/archive/refs/tags/hmmer-$(hmmer_version).tar.gz",
                  "fab109c67fb8077b32f7907bf07efbc071147be0670aee757c9a3ca7e2d485be")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/infernal-*/

mv ../easel-*/ easel
mv ../hmmer-*/ hmmer

# Replace the config.sub from infernal with a newer config.sub from
# easel.  Otherwise we get an error when running configure: "Invalid
# configuration `x86_64-linux-musl'."
cp easel/config.sub .

# generate configure script
autoreconf -vi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-pic --enable-threads --with-gsl

make
make install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || (arch(p) != "x86_64" && arch(p) != "i686"))

# The products that we will ensure are always built
products = [
    ExecutableProduct("cmemit", :cmemit),
    ExecutableProduct("cmconvert", :cmconvert),
    ExecutableProduct("cmfetch", :cmfetch),
    ExecutableProduct("cmpress", :cmpress),
    ExecutableProduct("cmbuild", :cmbuild),
    ExecutableProduct("cmstat", :cmstat),
    ExecutableProduct("cmsearch", :cmsearch),
    ExecutableProduct("cmscan", :cmscan),
    ExecutableProduct("cmcalibrate", :cmcalibrate),
    ExecutableProduct("cmalign", :cmalign),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
