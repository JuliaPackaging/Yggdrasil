version = v"1.17.42"
api_version = v"1.9.3"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "895108f4893d8db23467d76bf89e64e91d9e9555"),
]
