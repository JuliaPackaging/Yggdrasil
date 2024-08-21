version = v"1.17.6"
api_version = v"1.9.2"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "fd459f28041c176df23a0b7b791ff20a7689d237"),
]
