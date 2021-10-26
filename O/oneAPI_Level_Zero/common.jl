
version = v"1.4.1"
api_version = v"1.2.13"

# Collection of sources required to build this package
#
# The level zero repository contains both the API headers and a loader,
# which are versioned independently.
sources = [
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "551dd5810a3cea7a7e26ac4441da31878e804b53"),
]
