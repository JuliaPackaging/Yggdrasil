version = v"1.16.11"
api_version = v"1.9.2"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "3c1a820f2476c5ac1eb7dd8a18f3a77a53206c41"),
]
