# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")
build_xrt_cxxwrap(ARGS, v"2.26.0")
