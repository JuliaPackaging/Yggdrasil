version = v"1.9.4"
api_version = v"1.5.8"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "4ed13f327d3389285592edcf7598ec3cb2bc712e"),
]
