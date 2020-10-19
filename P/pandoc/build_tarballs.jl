using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
version = v"2.9.2"
pandoc_ver = "2.9.2.1"

sources = [
    ArchiveSource("https://github.com/jgm/pandoc/releases/download/$pandoc_ver/pandoc-$pandoc_ver-linux-amd64.tar.gz", "5b61a981bd2b7d48c1b4ba5788f1386631f97e2b46d0d1f1a08787091b4b0cf8"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("https://github.com/jgm/pandoc/releases/download/$pandoc_ver/pandoc-$pandoc_ver-macOS.zip", "c4847f7a6e6a02a7d1b8dc17505896d8a6e4c2ee9e8b325e47a0468036675307"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/jgm/pandoc/releases/download/$pandoc_ver/pandoc-$pandoc_ver-windows-i386.zip", "db5a8533b7e2ef38114e9788e56530bb6be330c326731692f236218682017d4d"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/jgm/pandoc/releases/download/$pandoc_ver/pandoc-$pandoc_ver-windows-x86_64.zip", "223f7ef1dd926394ee57b6b5893484e51100be8527bd96eec26e284774863084"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/16889a01b95a1b897abdfa2da191c1338f0333b2/COPYING.md", "2b0d4dda4bf8034e1506507a67f80f982131137afe62bf144d248f9faea31da4"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/16889a01b95a1b897abdfa2da191c1338f0333b2/COPYRIGHT", "39be98cc4d2906dd44abf8573ab91557e0b6d51f503d3a889dab0e8bcca1c43f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
if [[ "${target}" != *-mingw* ]]; then
    subdir="bin/"
fi
cp ${target}/pandoc-*/${subdir}pandoc${exeext} ${bindir}
cp ${target}/pandoc-*/${subdir}pandoc-citeproc${exeext} ${bindir}
chmod +x ${bindir}/*
install_license COPYRIGHT
install_license COPYING.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pandoc", :pandoc),
    ExecutableProduct("pandoc-citeproc", :pandoc_citeproc),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
