version = v"1.8.5"
api_version = v"1.4.8"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "474188ae004a5c76953a829477997bc341e70d48"),
]
