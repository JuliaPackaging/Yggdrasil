version = v"1.29.0"
api_version = v"1.16.0"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "b77ced661af97104f5cda03d49596274392f6aa4"), # tag v1.29.0
]
