
version = v"1.3.6"
api_version = v"1.1.2"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = [
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "bb89202bfd8c5e05b54d16fc8d9ad9e6c7142a09"),
]
