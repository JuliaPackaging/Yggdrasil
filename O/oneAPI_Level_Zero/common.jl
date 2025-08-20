version = v"1.22.4"
api_version = v"1.13.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "e3b6efdd91d67bb03024b266094afabd39e213bf"),
]
