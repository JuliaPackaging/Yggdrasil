using BinaryBuilder

name = "CLAP_Headers"
version = v"1.2.10"

sources = [
    GitSource("https://github.com/free-audio/clap.git", "195b42a004144fab0b3cf95e9c067187d15365b7"),
]

script = raw"""
cd clap
install_license LICENSE

# remove `artwork`: just takes space
rm -r artwork
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("include/clap/clap.h"),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
