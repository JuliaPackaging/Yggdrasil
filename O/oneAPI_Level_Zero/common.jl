version = v"1.13.1"
api_version = v"1.7.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "11c3649a05cf346157bbc6d93a330c33bb7ff7f4"),
]
