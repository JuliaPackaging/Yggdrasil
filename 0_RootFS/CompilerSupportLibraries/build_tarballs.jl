using BinaryBuilder

name = "CompilerSupportLibraries"
version = v"0.2.0"

# We don't actually have any sources, so just fake it out
sources = [
    ".",
]

# Bash recipe for building across all platforms
script = raw"""
if [[ ${target} == *mingw* ]]; then
    libdir=${prefix}/bin
else
    libdir=${prefix}/lib
fi
mkdir -p ${libdir}

file_valid()
{
    FILESTR=$(file -b $(realpath "$1"))
    if [[ ${target} == *apple* ]]; then
        if [[ "${FILESTR}" == Mach-O* ]] && [[ "${FILESTR}" != *"library stub"* ]]; then
            return 0
        fi
    elif [[ ${target} == *mingw* ]]; then
        if [[ "${FILESTR}" == PE* ]]; then
            return 0
        fi
    else
        if [[ "${FILESTR}" == ELF* ]]; then
            return 0
        fi
    fi
    return 1
}

# copy out all the libraries we can find
for d in /opt/${target}/${target}/lib*; do
    for l in ${d}/*.${dlext}*; do
        # Only copy it if it points to a real ELF/Mach-O/PE file
        if file_valid "${l}"; then
            cp -av "${l}" ${libdir}
        fi
    done
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgcc_s", "libgcc_s_sjlj", "libgcc_s_seh"], :libgcc_s),
    LibraryProduct("libstdc++", :libstdcxx),
    LibraryProduct("libgfortran", :libgfortran),
    LibraryProduct("libgomp", :libgomp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)
