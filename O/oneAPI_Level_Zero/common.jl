version = v"1.24.3"
api_version = v"1.13.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "7ae9d18f888dd4a9960e230b138ecd915ea187ac"),
]
