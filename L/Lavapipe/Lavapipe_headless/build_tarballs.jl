# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

# Lavapipe without the X11 window-system integration and its libraries, and without
# registering itself with the Vulkan loader: point VK_DRIVER_FILES or VK_ADD_DRIVER_FILES
# at `lvp_icd` to use it. Windows keeps its WSI; see the script.
name = "Lavapipe_headless"

build_lavapipe(ARGS, name, version, Dependency[]; headless=true)
