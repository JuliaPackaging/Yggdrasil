
version = v"1.0.13"
api_version = v"1.0.4"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = [
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "35bf3a9ad5375adae2c34864d8fc1a1f43f7d121"),
]
