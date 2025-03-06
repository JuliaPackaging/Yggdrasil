# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PhreeqcRM"
version = v"3.8.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/usgs-coupled/phreeqcrm.git", "eb70b492dbdc7818c62b4db39b9f589a2c5c0aed")
]

# Bash recipe for building across all platforms
script = raw"""

# so we can use a newer version of cmake
apk del cmake

cd $WORKSPACE/srcdir/phreeqcrm

# Configure
cmake -B Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DBUILD_SHARED_LIBS=ON \
    -DPHREEQCRM_BUILD_MPI=OFF \
    -DPHREEQCRM_USE_ZLIB=OFF \
    -DPHREEQCRM_DISABLE_OPENMP=OFF

# Compile
cmake --build Release --parallel ${nproc}

# Compile tests
cd Release/Tests
make all
cd ../..

# Deploy library
install -Dvm 755 "Release/libPhreeqcRM.${dlext}" -t "${libdir}"

# Deploy test executables
install -Dvm 755 "Release/libPhreeqcRM.${dlext}" -t "${libdir}"
install -Dvm 755 "Release/Tests/TestBMIdtor${exeext}" -t "${bindir}"
install -Dvm 755 "Release/Tests/TestRM${exeext}" -t "${bindir}"
install -Dvm 755 "Release/Tests/TestRMdtor${exeext}" -t "${bindir}"

# Store header files
cp irm_dll_export.h.in src/irm_dll_export.h
install -Dvm 644 src/*.h -t "${includedir}"
install -Dvm 644 src/IPhreeqcPhast/IPhreeqc/*.h -t "${includedir}"

# Store databases
install -Dvm 644 database/*.dat -t "${prefix}/share/phreeqcrm/database"
install -Dvm 644 Release/Tests/*.pqi -t "${prefix}/share/phreeqcrm/test_input"
install -Dvm 644 Release/Tests/phreeqc.dat -t "${prefix}/share/phreeqcrm/test_input"
install_license LICENSE

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# libgfortran 3 don't seem to work
platforms = filter(p -> !(libgfortran_version(p) == v"3"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libPhreeqcRM",      :libPhreeqcRM),
    ExecutableProduct("TestBMIdtor",    :TestBMIdtor),
    ExecutableProduct("TestRM",         :TestRM),
    ExecutableProduct("TestRMdtor",     :TestRMdtor)
]

# Dependencies that must be installed before this package can be built
dependencies = [
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
        BuildDependency("LLVMCompilerRT_jll"; platforms=filter(p -> Sys.isapple(p) && arch(p) == "aarch64", platforms)),
        HostBuildDependency(PackageSpec(; name="CMake_jll"))]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    julia_compat="1.9",
    preferred_gcc_version = v"9")
