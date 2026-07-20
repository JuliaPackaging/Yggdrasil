using BinaryBuilder

name = "ZoneDetect"
version = v"2024.9.13"  # there are no actual versions so this is the date of the commit used

sources = [
    GitSource("https://github.com/BertoldVdb/ZoneDetect",
              "082fa6b14815340d0f0d9e23b1ded318ba77c82c"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ZoneDetect

for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${patch}
done

make -C library install CC=${CC} prefix=${prefix} STRIP=
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzonedetect", :libzonedetect),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
