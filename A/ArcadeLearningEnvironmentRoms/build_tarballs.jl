# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ArcadeLearningEnvironmentRoms"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    FileSource("http://www.atarimania.com/roms/Roms.rar", "4e35879fbd3da7d008f80f8d3a48360b9513859aa6c694164e67d5a82daca498"),
    FileSource("https://raw.githubusercontent.com/mgbellemare/Arcade-Learning-Environment/v0.6.1/md5.txt", "218673cbeba56f3a7066293c259ae7b31ebece686bf3ff4ae4fe746e7d58a51e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/
unrar e Roms.rar
unzip ROMS.zip
mkdir $prefix/roms
for f in ROMS/*; do md5=`md5sum "$f" | awk '{print $1}'`; newname=`grep $md5 md5.txt | awk '{print $2}'`; if [[ $newname != "" ]]; then cp "$f" $prefix/roms/$newname; fi; done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("roms", :roms_dir)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
