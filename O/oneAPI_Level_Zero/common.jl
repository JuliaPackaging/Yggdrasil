version = v"1.28.2"
api_version = v"1.15.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "6369d8d642e9c7625e67f38664267f171b8e42dc"),
]
