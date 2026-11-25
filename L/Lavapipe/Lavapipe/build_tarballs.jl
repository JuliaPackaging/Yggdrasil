# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "Lavapipe"
ygg_version = v"26.2.4"  # New JLL version: device memory in a memfd on glibc (0006).

# Register the driver with the Vulkan loader. There is no loader-side driver list to push to
# the way the OpenCL driver JLLs use `OpenCL_jll.drivers`, so this goes through the loader's
# own discovery mechanism: VK_ADD_DRIVER_FILES *adds* to the drivers it finds, unlike
# VK_DRIVER_FILES, so a real GPU stays enumerable alongside this one. The loader reads it at
# vkCreateInstance, so setting it in __init__ is early enough.
init_block = raw"""
let sep = Sys.iswindows() ? ';' : ':',
    found = split(get(ENV, "VK_ADD_DRIVER_FILES", ""), sep; keepempty=false)
    if !(lvp_icd in found)
        ENV["VK_ADD_DRIVER_FILES"] = join(vcat(found, lvp_icd), sep)
    end
end
"""

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)
# The X11 WSI needs the xcb stack.
x11_dependencies = [
    Dependency("Xorg_libX11_jll"; compat="1.8.12", platforms=x11_platforms),
    Dependency("Xorg_libxcb_jll"; compat="1.17.1", platforms=x11_platforms),
    Dependency("Xorg_libxshmfence_jll"; compat="1.3.3", platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; compat="1.3.8", platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; compat="1.5.6", platforms=x11_platforms),
    Dependency("Xorg_xorgproto_jll"; compat="2024.1.1", platforms=x11_platforms),
]

build_lavapipe(ARGS, name, ygg_version, x11_dependencies; headless=false, init_block)
