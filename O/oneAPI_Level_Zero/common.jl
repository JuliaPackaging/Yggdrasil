version = v"1.32.0"
api_version = v"1.17.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "d3b3efbdaa27a0aef9a9812cc8fa4260557c1e7c"), # tag v1.32.0
]
