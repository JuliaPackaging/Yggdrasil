# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tblis"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/devinamatthews/tblis.git", "c4f81e08b2827e72335baa7bf91a245f72c43970")
    DirectorySource("./bundled")
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
    *"x86_64"*"linux"*"gnu"*) 
        export BLI_CONFIG=x86,reference
        export BLI_THREAD=openmp
        ;;
    *"x86_64"*"w64"*)
        # Windows lacks support for some instructions.
        # Building only for AMD processors.
        export BLI_CONFIG=amd,reference
        export BLI_THREAD=openmp
        # Wrapper for posix_memalign calls.
        patch src/memory/aligned_allocator.hpp < ${WORKSPACE}/srcdir/patches/aligned_allocator.hpp.mingw.patch
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
        export BLI_CONFIG=x86,reference
        export BLI_THREAD=openmp
        ;;
    *"x86_64"*"freebsd"*) 
        export BLI_CONFIG=x86,reference
        export BLI_THREAD=openmp
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

# Copy license file
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "windows")
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
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.  However we
    # need to make `CompilerSupportLibraries_jll` available on all platforms because libtci
    # needs libatomic.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0", clang_use_lld=false)
