# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Compose"
version = v"2.17.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://compose.obspm.fr/download/code/codehdf5.zip",
                  "f3f68203a50bb898abe31ee0b3dc750a1f1164c9e5d7fb9c4546b4eaa0cd172b"),
    FileSource("https://compose.obspm.fr/home", "d5aa9cb98faf17b6d9d98544ced475922c138ce79bb5282f995496e9927ec4b1";
               filename="homepage.html"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libnghttp2.*
fi

cd $WORKSPACE/srcdir
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/output.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/errors.patch

# Make `h5fc` available
mkdir bin
ln -s $bindir/h5pfc bin/h5fc
export PATH=$PATH:$WORKSPACE/srcdir/bin

make compose test_read_hdf5 test_read_opacity

install -Dvm 755 "compose${exeext}" "${bindir}/compose${exeext}"
install -Dvm 755 "test_read_hdf5${exeext}" "${bindir}/test_read_hdf5${exeext}"
install -Dvm 755 "test_read_opacity${exeext}" "${bindir}/test_read_opacity${exeext}"

install_license homepage.html
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# HDF5 on Windows does not provide `h5fc`
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("compose", :compose),
    ExecutableProduct("test_read_hdf5", :test_read_hdf5),
    ExecutableProduct("test_read_opacity", :test_read_opacity),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD 
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else. 
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="HDF5_jll"); compat="~1.14"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need to use the same `preferred_gcc_version` as HDF5 so that the Fortran 90 module files are compatible.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
