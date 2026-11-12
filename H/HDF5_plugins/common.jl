# Shared definitions for the HDF5 filter plugin recipes in this directory.
#
# Each recipe packages one filter from https://github.com/HDFGroup/hdf5_plugins
# as its own JLL. The `C` suffix of the JLL names marks them as the C
# implementations of the filters (as opposed to, e.g., pure Julia codecs).
#
# Upstream drives each filter through its own CMake superbuild that also
# downloads and builds the underlying codec. Here the codecs come from their own
# JLLs, so we compile the plugin source file(s) directly and link them against
# the codec JLL and HDF5_jll.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

# Version of the hdf5_plugins release (tag `2.2.0`, which targets HDF5 2.2.0)
const hdf5_plugins_version = v"2.2.0"

hdf5_plugins_sources() = [
    GitSource("https://github.com/HDFGroup/hdf5_plugins.git",
              "2b62ec75a6ea848899ef61bee8e034f8bab01f52"),
]

# The plugins do not use MPI, so they are built once per platform instead of once
# per MPI variant, and work with every HDF5_jll variant.
#
# HDF5_jll is only published for `libgfortran` 5 and the `cxx11` string ABI.
# Without these tags BinaryBuilder resolves HDF5_jll for `libgfortran3`/`cxx03`
# platforms, finds no artifact, and the headers are missing. Expand the ABI tags
# like the HDF5 recipe does and keep only the platforms HDF5_jll is available for.
function hdf5_plugins_platforms()
    platforms = supported_platforms()
    platforms = expand_cxxstring_abis(platforms)
    platforms = expand_gfortran_versions(platforms)
    filter!(platforms) do p
        VersionNumber(get(tags(p), "libgfortran_version", "0")) >= v"5" &&
            get(tags(p), "cxxstring_abi", "cxx11") != "cxx03"
    end
    return platforms
end

# The upstream filters are installed as loadable modules into `lib/plugin`.
# Keep that layout so the directory can be added to `HDF5_PLUGIN_PATH`.
hdf5_plugin_product(libname) =
    LibraryProduct(libname, Symbol(libname), ["lib/plugin", "bin/plugin"])

# Every filter is built against HDF5_jll for `H5PLextern.h` and the `H5Z`/`H5E`
# API. The coupling is tight on purpose: the plugin release `2.2.x` targets
# HDF5 `2.2.x`, so only HDF5_jll 2.2.* is allowed; `2.2.3` is the first build that is
# published for all platforms (same HDF5 2.2.0 library). Bump both together.
#
# HDF5_jll is only published as MPI variants and its headers include `mpi.h`
# (which of the variants is installed at build time does not matter). The plugin
# never calls the MPI parts of the API, so an MPI implementation is only needed
# for its header at build time and is not a dependency of the resulting JLL.
hdf5_plugin_dependencies(platforms, deps...) = [
    Dependency("HDF5_jll"; compat="~2.2.3"),
    deps...,
    BuildDependency("MPICH_jll"; platforms=filter(!Sys.iswindows, platforms)),
    BuildDependency("MicrosoftMPI_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# Prelude shared by all recipes. Upstream generates `<name>_config.h` headers
# from an autoconf-style template. They only carry `HAVE_*` feature macros, so
# one minimal header, copied under every name that is included, is enough.
const hdf5_plugin_prelude = raw"""
cd ${WORKSPACE}/srcdir/hdf5_plugins
mkdir -p cfg
cat > cfg/h5pl_config.h <<'END_CONFIG'
#define STDC_HEADERS 1
#define HAVE_MATH_H 1
#define HAVE_STDINT_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_UNISTD_H 1
END_CONFIG
for h in bitgroom bitround blosc blosc2 bzip bshuf granularbr lz4 lzf; do
    cp cfg/h5pl_config.h cfg/${h}_config.h
done

plugin_flags=(-O2 -fPIC -D_GNU_SOURCE -Icfg -I${includedir})
if [[ ${target} == *-mingw* ]]; then
    plugin_flags+=(-DH5_BUILT_AS_DYNAMIC_LIB)
fi
mkdir -p ${libdir}/plugin
"""

# Compile `sources` (paths relative to the hdf5_plugins checkout) into
# `<libname>` (e.g. `libh5zstd`) in `lib/plugin`, linking `libs` in addition to HDF5.
# `extra` is spliced in before the compiler call (e.g. to unpack bundled sources)
# and `cflags` is added to the compiler call.
function hdf5_plugin_script(libname, sources; libs="", cflags="", extra="")
    return hdf5_plugin_prelude * extra * """
\${CC} \${plugin_flags[@]} $cflags -shared -o \${libdir}/plugin/$libname.\${dlext} \\
    $(join(sources, " ")) -lhdf5 $libs -lm
install_license COPYING
"""
end
