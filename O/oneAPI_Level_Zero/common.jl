version = v"1.16.14"
api_version = v"1.9.2"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "0765f88f93ca39e8d8056aabab18c78de9d50cd4"),
]
