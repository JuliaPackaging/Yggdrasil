# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "USRPHardwareDriver"
version = v"4.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/EttusResearch/uhd.git", "6bd0be9cda5db97081e4f3ee3127c45eed21239c")
]

dependencies = [
    Dependency("boost_jll"; compat="=1.76.0"), # max gcc7
    Dependency("libusb_jll", compat="1.0.24"),
]

# Bash recipe for building across all platforms
script = raw"""
cd uhd/host

#code generators, only needed at build time
apk add py3-mako py3-ruamel.yaml

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_EXAMPLES=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_PYTHON_API=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# TODO: Windows has several issues with boost threads. There is a WIP branch:
# https://github.com/JuliaTelecom/uhd/tree/juliatelecom/patch-v4.1.0.1
platforms = expand_cxxstring_abis(filter!(p -> !Sys.iswindows(p) && !in(arch(p),("armv7l","armv6l")), supported_platforms(;experimental=true)))

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("uhd_cal_rx_iq_balance", :uhd_cal_rx_iq_balance),
    ExecutableProduct("uhd_cal_tx_iq_balance", :uhd_cal_tx_iq_balance),
    ExecutableProduct("uhd_find_devices", :uhd_find_devices),
    ExecutableProduct("uhd_adc_self_cal", :uhd_adc_self_cal),
    ExecutableProduct("uhd_cal_tx_dc_offset", :uhd_cal_tx_dc_offset),
    ExecutableProduct("uhd_config_info", :uhd_config_info),
    ExecutableProduct("uhd_image_loader", :uhd_image_loader),
    ExecutableProduct("uhd_usrp_probe", :uhd_usrp_probe),
    LibraryProduct("libuhd", :libuhd)
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc7 constraint from boost
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
