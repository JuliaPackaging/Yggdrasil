
version = v"1.5.0"
api_version = v"1.2.43"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "556cbac1a2adce87ff28c32813f23543700d95f2"),
]
