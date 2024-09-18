using BinaryBuilder, Pkg

name = "S2Geography"
version = v"0.1.2"
sources = [
    GitSource("https://github.com/paleolimbot/S2Geography.git", "26b65bb0a60361adfcc72b0ac427302cbf10b040"),
    DirectorySource("./bundled"),
]

# TODO: fix the build
# by pointing to the right s2 and abseil paths
# from the JLLs.
script = raw"""
cd ${WORKSPACE}/srcdir/s2geography-*
atomic_patch -p1 ../patches/msvc_to_win32_target.patch
mkdir build
cd build
cmake .. 
    -DS2GEOGRAPHY_S2_SOURCE=SYSTEM 
    -DS2GEOGRAPHY_BUILD_TESTS=OFF
    -DS2GEOGRAPHY_BUILD_EXAMPLES=OFF
    -DS2GEOGRAPHY_CODE_COVERAGE=OFF
cmake --build .
"""

platforms = supported_platforms()

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# The following platforms are also excluded by s2geometry, which we depend on.

# Only 64-bit platforms supported
filter!(p -> nbits(p) == 64, platforms)
# We are missing some dependencies (Abseil) for aarch64-freebsd, 
# can be re-enabled in the future when we have them
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
# Compilation fails for powerpc:
#     /workspace/srcdir/s2geometry/src/s2/s2edge_crossings.cc:120:31: error: ‘(6.15348059642740421245081038903225e-15l / 5.40431955284459475358983848622456e+16l)’ is not a constant expression
filter!(p -> arch(p) != "powerpc64le", platforms)

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libs2geography", :libs2geography),
    LibraryProduct("libs2geography_geoarrow", :libs2geography_geoarrow),
]

dependencies = [
    Dependency(PackageSpec(name="abseil_cpp_jll", uuid="43133aba-3931-5066-b004-a34c79b93f2e"), compat="20240116.2.0"),
    Dependency(PackageSpec(name="S2Geometry_jll", uuid="846536d6-5c10-5069-b47f-45525c463cf9"), compat="0.11.1"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")