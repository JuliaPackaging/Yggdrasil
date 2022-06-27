version = v"1.8.1"
api_version = v"1.4.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "108c4ded66ee9bcd225358e723fe9173c15171d3"),
]
