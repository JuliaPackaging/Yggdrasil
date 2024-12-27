# BSD 3-Clause License
#
# Copyright (c) 2017-2019, Battelle Memorial Institute; Lawrence Livermore National Security, LLC; Alliance for Sustainable Energy, LLC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Build count: 1
using BinaryBuilder

HELICS_VERSION = v"3.6.0"
HELICS_SHA = "e111ac5d92e808f27e330afd1f8b8ca4d86adf6ccd74e3280f2d40fb3e0e2ce9"

sources = [
    ArchiveSource("https://github.com/GMLC-TDC/HELICS/releases/download/v$HELICS_VERSION/Helics-v$HELICS_VERSION-source.tar.gz",
                  "$HELICS_SHA"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

script = raw"""
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    export MACOSX_DEPLOYMENT_TARGET=10.15
fi

# Need newer CMake than provided by the default image (currently requires at least 3.22)
apk del cmake

cd $WORKSPACE/srcdir

cmake -B build \
   -DCMAKE_FIND_ROOT_PATH="${prefix}" \
   -DCMAKE_INSTALL_PREFIX="${prefix}" \
   -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
   -DCMAKE_BUILD_TYPE=Release \
   -DHELICS_BUILD_TESTS=OFF \
   ./

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

if [[ "${target}" == *-mingw* ]]; then
    # Remove a broken link that we don't need anyway
    rm ${prefix}/bin/libzmq.dll.a
fi
"""

products = [
    LibraryProduct("libhelics", :libhelics),
]


platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("ZeroMQ_jll"),
    BuildDependency("boost_jll"),
    HostBuildDependency("CMake_jll"),
]

# Build 'em!
build_tarballs(
    ARGS,
    "HELICS",
    HELICS_VERSION,
    sources,
    script,
    platforms,
    products,
    dependencies,
    preferred_gcc_version=v"9",
    julia_compat="1.6",
)
