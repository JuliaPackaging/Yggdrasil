
version = v"1.7.15"
api_version = v"1.3.7"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "bb7fff05b801e26c3d7858e03e509d1089914d59"),
]
