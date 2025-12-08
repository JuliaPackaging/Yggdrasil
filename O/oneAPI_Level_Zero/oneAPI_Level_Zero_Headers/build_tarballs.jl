# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

include("../common.jl")
name = "oneAPI_Level_Zero_Headers"

# Bash recipe for building across all platforms
script = raw"""
cd level-zero
install_license LICENSE

mkdir -p ${includedir}/level_zero
rsync --archive --exclude="*.py" include/ ${includedir}/level_zero
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/level_zero/ze_api.h", :ze_api)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, api_version, sources, script, platforms, products, dependencies)
