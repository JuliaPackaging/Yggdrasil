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

using BinaryBuilder

HELICS_VERSION = v"2.6.1"
HELICS_SHA = "4b9a733a568ae8e6492f93abcd43f1aa9c53b233edcbeb0ab188dcc0d73ac928"

sources = [
    ArchiveSource("https://github.com/GMLC-TDC/HELICS/releases/download/v$HELICS_VERSION/Helics-v$HELICS_VERSION-source.tar.gz",
                  "$HELICS_SHA"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build
CMAKE_ARGS="-DCMAKE_FIND_ROOT_PATH="${prefix}" -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release"
HELICS_ARGS="-DHELICS_BUILD_TESTS=OFF"
cmake ${CMAKE_ARGS} ${HELICS_ARGS} ..
make -j${nproc}
make install
if [[ "${target}" == *-mingw* ]]; then
    # Remove a broken link that we don't need anyway
    rm ${prefix}/bin/libzmq.dll.a
fi
"""

products = [
    LibraryProduct("libhelicsSharedLib", :libhelicsSharedLib),
]

platforms = expand_cxxstring_abis(supported_platforms(exclude = Sys.isfreebsd))

dependencies = [
    Dependency("ZeroMQ_jll"),
    BuildDependency("boost_jll"),
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
    ; preferred_gcc_version=v"7",
)
