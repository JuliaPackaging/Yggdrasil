
version = v"1.7.9"
api_version = v"1.3.7"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = [
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "78f08cc338d70ac60a8f61084ad194fa0dbc90b0"),
]
