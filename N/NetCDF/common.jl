# Shared definitions for the NetCDF core recipe (N/NetCDF) and the separately
# packaged NetCDF plugins (N/NCH5*, N/NCZ*).
#
# All of these recipes are built from the same netcdf-c release. The plugins
# are compiled directly from netcdf-c's `plugins/` directory against the
# headers and the `config.h` that NetCDF_jll installs.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
include(joinpath(@__DIR__, "..", "..", "platforms", "mpi.jl"))

# The version of the JLLs is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
upstream_version = v"4.10.1"

# Version of the NetCDF core recipe. Remember to always bump this.
# The plugins are built against exactly this version of NetCDF_jll.
netcdf_version_offset = v"1.0.2"

netcdf_jll_version(offset) =
    VersionNumber(upstream_version.major * 100 + offset.major,
                  upstream_version.minor * 100 + offset.minor,
                  upstream_version.patch * 100 + offset.patch)

netcdf_core_version = netcdf_jll_version(netcdf_version_offset)

# Collection of sources required to build NetCDF and its plugins
netcdf_sources = [
    ArchiveSource("https://downloads.unidata.ucar.edu/netcdf-c/$(upstream_version)/netcdf-c-$(upstream_version).tar.gz",
                  "db3b69ff4a5ee1a7d79a5c36664d2128b752c266e966369fcf7311ec5f927564"),
]

# HDF5 provides the library NetCDF is built on and `hdf5.h` for the plugins.
const netcdf_hdf5_dependency = Dependency("HDF5_jll"; compat="2.2.1")

# HDF5 is built with several MPI variants, so NetCDF and everything that
# builds against it needs the MPI platform tag.
netcdf_augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

function netcdf_platforms()
    platforms, platform_dependencies = MPI.augment_platforms(supported_platforms())
    return platforms, platform_dependencies
end

# Location of the plugins relative to the prefix. This is the default
# location where netcdf-c installs its plugins (<prefix>/hdf5/lib/plugin).
const plugin_dir = "hdf5/lib/plugin"

# Where NetCDF_jll installs the `config.h` it was configured with.
const netcdf_config_dir = "share/netcdf/plugin-build"

# Build the shell script for a single-plugin recipe.
#
#  - `plugin`:   base name of the plugin library, e.g. "lib__nch5zstd"
#  - `sources`:  C files in netcdf-c's `plugins/` directory forming the plugin
#  - `defines`:  preprocessor definitions that `configure` would normally have
#                put into `config.h` for the optional filters
#  - `libs`:     libraries to link against
function netcdf_plugin_script(plugin, sources; defines=String[], libs=String[])
    return """
PLUGIN=$(plugin)
SOURCES="$(join(sources, " "))"
DEFINES="$(join(defines, " "))"
LIBS="$(join(libs, " "))"
PLUGIN_DIR=$(plugin_dir)
CONFIG_DIR=$(netcdf_config_dir)
""" * raw"""
cd ${WORKSPACE}/srcdir/netcdf-c*/plugins

# `config.h` is provided by NetCDF_jll. Remove the settings for the optional
# filters: whether they are available depends on this plugin, not on how the
# NetCDF library was configured.
mkdir -p ${WORKSPACE}/plugin-config
sed -E '/^#[[:space:]]*define[[:space:]]+HAVE_(BLOSC|ZSTD|SZ|BZ2|LOCAL_BZ2)([[:space:]]|$)/d' \
    ${prefix}/${CONFIG_DIR}/config.h > ${WORKSPACE}/plugin-config/config.h

CFLAGS="-O2 -fPIC -Wno-implicit-function-declaration"
CPPFLAGS="-DHAVE_CONFIG_H ${DEFINES} -I${WORKSPACE}/plugin-config -I. -I${includedir}"

OBJECTS=""
for src in ${SOURCES}; do
    ${CC} ${CFLAGS} ${CPPFLAGS} -c ${src} -o ${src%.c}.o
    OBJECTS="${OBJECTS} ${src%.c}.o"
done

if [[ ${target} == *-apple-* ]]; then
    SHARED_FLAG="-dynamiclib"
else
    SHARED_FLAG="-shared"
fi

mkdir -p ${prefix}/${PLUGIN_DIR}
${CC} ${SHARED_FLAG} ${CFLAGS} -o ${prefix}/${PLUGIN_DIR}/${PLUGIN}.${dlext} \
    ${OBJECTS} -L${libdir} ${LIBS}

install_license ../COPYRIGHT
"""
end

netcdf_plugin_product(plugin) =
    LibraryProduct(plugin, Symbol(plugin), [plugin_dir])

# Dependencies common to all plugins. NetCDF_jll provides the headers and
# `config.h`; HDF5_jll provides `hdf5.h` and `H5allocate_memory` et al.
# `netcdf_runtime` is true for plugins that call into `libnetcdf`.
function netcdf_plugin_dependencies(platform_dependencies; netcdf_runtime=false)
    netcdf = if netcdf_runtime
        Dependency("NetCDF_jll"; compat=string(netcdf_core_version))
    else
        BuildDependency(PackageSpec(name="NetCDF_jll", version=netcdf_core_version))
    end
    deps = [
        netcdf,
        netcdf_hdf5_dependency,
    ]
    append!(deps, platform_dependencies)
    return deps
end

# Build tarballs for a single plugin package.
function build_netcdf_plugin(ARGS, name, plugin, plugin_sources, extra_dependencies;
                             version_offset=v"1.0.0", defines=String[], libs=String[],
                             netcdf_runtime=false)
    platforms, platform_dependencies = netcdf_platforms()
    dependencies = netcdf_plugin_dependencies(platform_dependencies; netcdf_runtime)
    append!(dependencies, extra_dependencies)
    script = netcdf_plugin_script(plugin, plugin_sources; defines, libs=["-lhdf5"; libs])
    products = [netcdf_plugin_product(plugin)]

    # Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
    # (MPItrampoline will skip its automatic initialization.)
    ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

    build_tarballs(ARGS, name, netcdf_jll_version(version_offset), netcdf_sources, script,
                   platforms, products, dependencies;
                   augment_platform_block=netcdf_augment_platform_block,
                   julia_compat="1.6", preferred_gcc_version=v"8")
end
