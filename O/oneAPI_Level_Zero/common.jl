version = v"1.11.0"
api_version = v"1.6.3"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "f35123bead54a471a7e5f3bf8d439a4a44527d8e"),
]
