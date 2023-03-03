version = v"1.8.12"
api_version = v"1.4.8"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "23641699b9e2a68f61e6f12a61a27d1f1ef54570"),
]
