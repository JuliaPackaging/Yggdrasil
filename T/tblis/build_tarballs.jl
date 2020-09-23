# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tblis"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/devinamatthews/tblis.git", "3e4c4b82943726c443b6f408c9c9791dcad7a847")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd tblis/

for i in ./Makefile.* ./configure*; do

    # Building in container forbids -march options
    sed -i "s/-march[^ ]*//g" $i

done

case ${target} in
    # Unlike stated in Wiki, 
    # TBLIS automatically detects threading model.
    *"x86_64"*"linux"*) 
        export BLI_CONFIG=x86
        export BLI_THREAD=openmp
        ;;
    *"x86_64"*"w64"*)
        # Windows lacks support for some instructions.
        # Building only for AMD processors.
        export BLI_CONFIG=amd
        export BLI_THREAD=openmp
        # Wrapper for posix_memalign calls.
        echo 'aW5saW5lIGludCBwb3NpeF9tZW1hbGlnbih2b2lkICoqbWVtcHRyLCBzaXplX3QgYWxpZ25tZW50LCBzaXplX3Qgc2l6ZSkKeyAqbWVtcHRyID0gMDsgKm1lbXB0ciA9IF9hbGlnbmVkX21hbGxvYyhhbGlnbm1lbnQsIHNpemUpOyAKICAgcmV0dXJuICgqbWVtcHRyID09IDAgJiYgc2l6ZSAhPSAwKTsgfQo=' | base64 -d | cat - src/memory/aligned_allocator.hpp >> aligned_allocator_new.hpp
        mv aligned_allocator_new.hpp src/memory/aligned_allocator.hpp
        # Additional linking parameter needed for MinGW Autoconf.
        # Update Autoconf parameters and refresh.
        cd src/external/tci
        echo "AM_LDFLAGS=-no-undefined" >> Makefile.am
        echo "lib_libtci_la_LDFLAGS=-no-undefined" >> Makefile.am
        update_configure_scripts --reconf
        cd ../../..
        sed -i "s/.*AM_LDFLAGS.*/AM_LDFLAGS=-lpthread -no-undefined/" Makefile.am
        echo "lib_libtblis_la_LDFLAGS=-no-undefined" >> Makefile.am
        update_configure_scripts --reconf
        ;;
    *"x86_64"*"apple"*) 
        export BLI_CONFIG=x86
        export BLI_THREAD=openmp
        export CC=gcc
        export CXX=g++
        ;;
    *"x86_64"*"freebsd"*) 
        export BLI_CONFIG=x86
        export BLI_THREAD=openmp
        export CC=gcc
        export CXX=g++
        ;;
    *)
        ;; 

esac

CFG_OPTION_POSIX="--prefix=${prefix} --build=${MACHTYPE} --host=${target}"
# ./configure will warn about --enable-thread-model but it is actually effective.
CFG_OPTION_TBLIS="--enable-config=${BLI_CONFIG} --enable-thread-model=${BLI_THREAD}"

./configure ${CFG_OPTION_TBLIS} ${CFG_OPTION_POSIX}
make -j${nproc}
make install

if [[ ${target} == *"x86_64"*"w64"* ]]; then
    # Rename binary files for MinGW
    mv ${prefix}/bin/libtci-0.dll ${prefix}/bin/libtci.dll 
    mv ${prefix}/bin/libtblis-0.dll ${prefix}/bin/libtblis.dll 
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    Linux(:x86_64, libc=:musl),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libtci", :tci),
    LibraryProduct("libtblis", :tblis)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5")
