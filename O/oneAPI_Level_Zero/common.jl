
version = v"1.0.16"
api_version = v"1.0.4"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = [
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "7281f67ebdec5b2ae93059bff64829fb42e01a7e"),
]
