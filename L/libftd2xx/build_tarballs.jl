# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libftd2xx"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    "https://www.ftdichip.com/Drivers/CDM/CDM%20v2.12.28%20WHQL%20Certified.zip" =>
    "82db36f089d391f194c8ad6494b0bf44c508b176f9d3302777c041dad1ef7fe6",

    "https://www.ftdichip.com/Drivers/D2XX/Linux/libftd2xx-i386-1.4.8.gz" =>
    "84c9aaf7288a154faf0e2814ba590ec965141c698b2a00bffc94d8e0c7ebeb4c",

    "https://www.ftdichip.com/Drivers/D2XX/Linux/libftd2xx-x86_64-1.4.8.gz" =>
    "815d880c5ec40904f062373e52de07b2acaa428e54fece98b31e6573f5d261a0",

    "https://www.ftdichip.com/Drivers/D2XX/Linux/libftd2xx-arm-v7-hf-1.4.8.gz" =>
    "81c8556184e9532a3a19ee6915c3a43110dc208116967a4d3e159f00db5d16e1",

    "https://www.ftdichip.com/Drivers/D2XX/Linux/libftd2xx-arm-v8-1.4.8.gz" =>
    "e353cfa94069dee6d5bba1c4d8a19b0fd2bf3db1e8bbe0c3b9534fdfaf7a55ed",

    "https://www.ftdichip.com/Drivers/D2XX/MacOSX/D2XX1.4.16.dmg" =>
    "757ef22c3e48c2022974c2110d25ee45dd09bff8f397c8432018c50fb4b2d785",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd $WORKSPACE/srcdir
mkdir $prefix/lib
if [[ ${target} == x86_64-linux-* ]]; then     tar zxvf libftd2xx-x86_64-1.4.8.gz;     cp release/build/*.so* $prefix/lib; fi
if [[ ${target} == i686-linux-* ]]; then     tar zxvf libftd2xx-i386-1.4.8.gz;     cp release/build/*.so* $prefix/lib; fi
if [[ ${target} == aarch64-linux-* ]]; then     tar zxvf libftd2xx-arm-v8-1.4.8.gz;     cp release/build/*.so* $prefix/lib; fi
if [[ ${target} == arm-linux-* ]]; then     tar zxvf libftd2xx-arm-v7-hf-1.4.8.gz;     cp release/build/*.so* $prefix/lib; fi
if [[ %{target} == x86_64-apple-darwin* ]]; then     apk add p7zip;     7z x D2XX1.4.16.dmg;     cp release/D2XX/*.dylib* $prefix/lib; fi
if [[ ${target} == x86_64-w64-mingw32 ]]; then     cp amd64/*.dll $prefix/lib; fi
if [[ ${target} == i686-w64-ming32 ]]; then     cp i386/*.dll $prefix/lib; fi
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:i686, libc=:glibc)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libftd2xx", :libftd2xx)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
