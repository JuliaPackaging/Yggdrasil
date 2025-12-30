version = v"1.25.1"
api_version = v"1.13.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "a93cb081169fe11ec42da3f620839d2feb64742a"),
]
