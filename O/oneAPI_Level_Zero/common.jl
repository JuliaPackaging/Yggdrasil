version = v"1.8.8"
api_version = v"1.4.8"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "32c4431d731bc2ba7b5b88b32335063efa65e076"),
]
