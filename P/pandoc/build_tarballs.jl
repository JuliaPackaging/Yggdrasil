using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
version = v"2.9.2"
pandoc_ver = "2.9.2.1"

sources = [
    FileSource("https://github.com/jgm/pandoc/releases/download/$pandoc_ver/pandoc-$pandoc_ver-linux-amd64.tar.gz", "5b61a981bd2b7d48c1b4ba5788f1386631f97e2b46d0d1f1a08787091b4b0cf8"),
    FileSource("https://github.com/jgm/pandoc/releases/download/$pandoc_ver/pandoc-$pandoc_ver-macOS.zip", "c4847f7a6e6a02a7d1b8dc17505896d8a6e4c2ee9e8b325e47a0468036675307"),
    FileSource("https://github.com/jgm/pandoc/releases/download/$pandoc_ver/pandoc-$pandoc_ver-windows-i386.zip", "db5a8533b7e2ef38114e9788e56530bb6be330c326731692f236218682017d4d"),
    FileSource("https://github.com/jgm/pandoc/releases/download/$pandoc_ver/pandoc-$pandoc_ver-windows-x86_64.zip", "223f7ef1dd926394ee57b6b5893484e51100be8527bd96eec26e284774863084"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/master/COPYING.md", "2b0d4dda4bf8034e1506507a67f80f982131137afe62bf144d248f9faea31da4"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/master/COPYRIGHT", "39be98cc4d2906dd44abf8573ab91557e0b6d51f503d3a889dab0e8bcca1c43f"),
]

# Bash recipe for building across all platforms
script = "pandoc_ver=$pandoc_ver\n"*raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${prefix}/lib ${prefix}/bin ${prefix}/share

if [[ ${target} == x86_64-*mingw* ]]; then
    unzip pandoc-$pandoc_ver-windows-x86_64.zip
    cp pandoc-${pandoc_ver}/pandoc.exe ${prefix}/bin
    cp pandoc-${pandoc_ver}/pandoc-citeproc.exe ${prefix}/bin 
    chmod +x ${prefix}/bin/*
elif [[ ${target} == i686-*mingw* ]]; then
    unzip pandoc-$pandoc_ver-windows-i386.zip
    cp pandoc-${pandoc_ver}/pandoc.exe ${prefix}/bin
    cp pandoc-${pandoc_ver}/pandoc-citeproc.exe ${prefix}/bin
    chmod +x ${prefix}/bin/*
elif [[ ${target} == *apple* ]]; then
    unzip pandoc-$pandoc_ver-macOS.zip
    cp pandoc-${pandoc_ver}/bin/pandoc ${prefix}/bin
    cp pandoc-${pandoc_ver}/bin/pandoc-citeproc ${prefix}/bin
elif [[ ${target} == x86_64-linux-gnu* ]]; then
    tar -zxf pandoc-${pandoc_ver}-linux-amd64.tar.gz
    cp pandoc-${pandoc_ver}/bin/pandoc ${prefix}/bin
    cp pandoc-${pandoc_ver}/bin/pandoc-citeproc ${prefix}/bin
fi
install_license COPYRIGHT
install_license COPYING.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64),
    MacOS(),
    Windows(:x86_64),
    Windows(:i686),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pandoc", :pandoc),
    ExecutableProduct("pandoc-citeproc", :pandoc_citeproc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
	Dependency("Zlib_jll"), 
	Dependency("Libiconv_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
