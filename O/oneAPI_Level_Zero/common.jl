version = v"1.16.1"
api_version = v"1.9.1"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "ac99dbfb937f0715171eb39f83b5fadf20474b68"),
]
