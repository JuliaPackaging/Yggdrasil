
version = v"1.2.3"
api_version = v"1.1.2"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = [
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "0d30b1fa712253c68bfdfa3863d380df4301b8a4"),
]
