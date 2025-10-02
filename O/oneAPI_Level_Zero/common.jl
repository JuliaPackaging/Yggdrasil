version = v"1.24.2"
api_version = v"1.13.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "ff8c99d4abda00fba6d92548a9cb2f721764d9d0"),
]
