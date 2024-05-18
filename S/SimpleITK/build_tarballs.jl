using BinaryBuilder, Pkg

name = "SimpleITK"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://github.com/SimpleITK/SimpleITK/releases/download/v$(version)/SimpleITK-$(version).tar.gz", "b07bb98707556ebc2b79aac22dc14950749f509e5b43da8043233275aa55488a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mount -t tmpfs -o size=12G tmpfs /workspace/srcdir
cd ..
cd ..
cd workspace/srcdir
wget https://github.com/SimpleITK/SimpleITK/releases/download/v2.2.0/SimpleITK-2.2.0.tar.gz
tar -xvzf ./SimpleITK-2.2.0.tar.gz 
mkdir SimpleITK-build
cd SimpleITK-build/
cmake -DCMAKE_INSTALL_PREFIX:FILEPATH=/workspace/destdir -DCMAKE_BUILD_TYPE:STRING=RELEASE -DBUILD_SHARED_LIBS:BOOL=ON ../SimpleITK-2.2.0/SuperBuild
make -j${nproc}
rm -rf /workspace/srcdir/SimpleITK-build/ITK-build/lib/cmake
cp /workspace/srcdir/SimpleITK-build/ITK-build/lib/* /workspace/destdir/lib
cd /workspace/destdir/share
mkdir licenses
cd licenses
mkdir SimpleITK
cd SimpleITK
cp /workspace/destdir/share/doc/SimpleITK-2.2/* ./ 
logout
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libSimpleITKIO-2.2", :libSimpleITKIO),
    LibraryProduct("libSimpleITKRegistration-2.2", :libSimpleITKRegistration),
    LibraryProduct("libSimpleITKCommon-2.2", :libSimpleITKCommon)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0", verbose=true)
