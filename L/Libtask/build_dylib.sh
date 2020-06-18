#!/bin/bash

# target=x86_64-linux-gnu
cd $WORKSPACE/srcdir

RELEASES=(
    arm-linux-gnueabihf@v1_0@https://julialang-s3.julialang.org/bin/linux/armv7l/1.0/julia-1.0.0-linux-armv7l.tar.gz
    arm-linux-gnueabihf@v1_2@https://julialang-s3.julialang.org/bin/linux/armv7l/1.2/julia-1.2.0-linux-armv7l.tar.gz
    arm-linux-gnueabihf@v1_3@https://julialang-s3.julialang.org/bin/linux/armv7l/1.3/julia-1.3.0-linux-armv7l.tar.gz
    aarch64-linux-gnu@v1_0@https://julialang-s3.julialang.org/bin/linux/aarch64/1.0/julia-1.0.4-linux-aarch64.tar.gz
    aarch64-linux-gnu@v1_1@https://julialang-s3.julialang.org/bin/linux/aarch64/1.1/julia-1.1.1-linux-aarch64.tar.gz
    aarch64-linux-gnu@v1_2@https://julialang-s3.julialang.org/bin/linux/aarch64/1.2/julia-1.2.0-linux-aarch64.tar.gz
    aarch64-linux-gnu@v1_3@https://julialang-s3.julialang.org/bin/linux/aarch64/1.3/julia-1.3.0-linux-aarch64.tar.gz
    i686-linux-gnu@v1_0@https://julialang-s3.julialang.org/bin/linux/x86/1.0/julia-1.0.0-linux-i686.tar.gz
    i686-linux-gnu@v1_1@https://julialang-s3.julialang.org/bin/linux/x86/1.1/julia-1.1.0-linux-i686.tar.gz
    i686-linux-gnu@v1_2@https://julialang-s3.julialang.org/bin/linux/x86/1.2/julia-1.2.0-linux-i686.tar.gz
    i686-linux-gnu@v1_3@https://julialang-s3.julialang.org/bin/linux/x86/1.3/julia-1.3.0-linux-i686.tar.gz
    x86_64-linux-gnu@v1_0@https://julialang-s3.julialang.org/bin/linux/x64/1.0/julia-1.0.0-linux-x86_64.tar.gz
    x86_64-linux-gnu@v1_1@https://julialang-s3.julialang.org/bin/linux/x64/1.1/julia-1.1.0-linux-x86_64.tar.gz
    x86_64-linux-gnu@v1_2@https://julialang-s3.julialang.org/bin/linux/x64/1.2/julia-1.2.0-linux-x86_64.tar.gz
    x86_64-linux-gnu@v1_3@https://julialang-s3.julialang.org/bin/linux/x64/1.3/julia-1.3.0-linux-x86_64.tar.gz
    powerpc64le-linux-gnu@v1_0@http://cxan.kdr2.com/julia/releases/julia-1.0.0-linux-ppc64le.tar.gz
    powerpc64le-linux-gnu@v1_1@http://cxan.kdr2.com/julia/releases/julia-1.1.0-linux-ppc64le.tar.gz
    powerpc64le-linux-gnu@v1_2@http://cxan.kdr2.com/julia/releases/julia-1.2.0-linux-ppc64le.tar.gz
    powerpc64le-linux-gnu@v1_3@http://cxan.kdr2.com/julia/releases/julia-1.3.0-linux-ppc64le.tar.gz
    x86_64-w64-mingw32@v1_0@http://cxan.kdr2.com/julia/releases/julia-1.0.0-win64.tar.gz
    x86_64-w64-mingw32@v1_1@http://cxan.kdr2.com/julia/releases/julia-1.1.0-win64.tar.gz
    x86_64-w64-mingw32@v1_2@http://cxan.kdr2.com/julia/releases/julia-1.2.0-win64.tar.gz
    x86_64-w64-mingw32@v1_3@http://cxan.kdr2.com/julia/releases/julia-1.3.0-win64.tar.gz
    i686-w64-mingw32@v1_0@http://cxan.kdr2.com/julia/releases/julia-1.0.0-win32.tar.gz
    i686-w64-mingw32@v1_1@http://cxan.kdr2.com/julia/releases/julia-1.1.0-win32.tar.gz
    i686-w64-mingw32@v1_2@http://cxan.kdr2.com/julia/releases/julia-1.2.0-win32.tar.gz
    i686-w64-mingw32@v1_3@http://cxan.kdr2.com/julia/releases/julia-1.3.0-win32.tar.gz
    x86_64-apple-darwin14@v1_0@http://cxan.kdr2.com/julia/releases/julia-1.0.0-mac64.tar.gz
    x86_64-apple-darwin14@v1_1@http://cxan.kdr2.com/julia/releases/julia-1.1.0-mac64.tar.gz
    x86_64-apple-darwin14@v1_2@http://cxan.kdr2.com/julia/releases/julia-1.2.0-mac64.tar.gz
    x86_64-apple-darwin14@v1_3@http://cxan.kdr2.com/julia/releases/julia-1.3.0-mac64.tar.gz
)

for RELEASE in ${RELEASES[@]}; do
    REL_TARGET=$(echo $RELEASE | cut -d@ -f1)
    if [ $target != $REL_TARGET ]; then
        continue
    fi
    rm -f *.tar.gz
    rm -fr julia
    wget $(echo $RELEASE | cut -d@ -f3)
    tar xzvf *tar.gz
    rm -f *.tar.gz
    mv julia* julia
    export JULIA_VERSION=$(echo $RELEASE | cut -d@ -f2)
    if [ $target = x86_64-apple-darwin14 ]; then
        export JULIA_HOME=$(pwd)/julia/Contents/Resources/julia
    else
        export JULIA_HOME=$(pwd)/julia
        # export JULIA_HOME=/home/kdr2/programs/julia-1.1.0
    fi
    make -C Libtask.jl/deps
done

# https://juliapackaging.github.io/BinaryBuilder.jl/dev/build_tips/#Installing-the-license-file-1
install_license Libtask.jl/LICENSE
