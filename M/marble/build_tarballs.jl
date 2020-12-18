# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "marble"
version = v"20.12.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/KDE/marble/archive/v20.12.0.tar.gz", "20ea52f071bd255109d723565fc46eb46ee4415acb402f5d45f6c6dbd6b312b7"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd marble-20.12.0/
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/win32.patch"
mkdir build
cd build/
apk del ninja
apk add g++
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../.
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"),
    Platform("x86_64", "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libastro", :astro),
    LibraryProduct("libCycleStreetsPlugin", :CycleStreetsPlugin, "plugins"),
    LibraryProduct("libNominatimSearchPlugin", :NominatimSearchPlugin, "plugins"),
    LibraryProduct("libPn2Plugin", :Pn2Plugin, "plugins"),
    LibraryProduct("libHostipPlugin", :HostipPlugin, "plugins"),
    LibraryProduct("libStarsPlugin", :StarsPlugin, "plugins"),
    LibraryProduct("libOpenLocationCodeSearchPlugin", :OpenLocationCodeSearchPlugin, "plugins"),
    LibraryProduct("libLicense", :License, "plugins"),
    LibraryProduct("libCachePlugin", :CachePlugin, "plugins"),
    LibraryProduct("libYoursPlugin", :YoursPlugin, "plugins"),
    LibraryProduct("libGosmoreRoutingPlugin", :GosmoreRoutingPlugin, "plugins"),
    LibraryProduct("libElevationProfileFloatItem", :ElevationProfileFloatItem, "plugins"),
    LibraryProduct("libLocalOsmSearchPlugin", :LocalOsmSearchPlugin, "plugins"),
    LibraryProduct("libMapQuestPlugin", :MapQuestPlugin, "plugins"),
    LibraryProduct("libGeoUriPlugin", :GeoUriPlugin, "plugins"),
    LibraryProduct("libRoutinoPlugin", :RoutinoPlugin, "plugins"),
    LibraryProduct("libJsonPlugin", :JsonPlugin, "plugins"),
    LibraryProduct("libMeasureTool", :MeasureTool, "plugins"),
    LibraryProduct("libFoursquarePlugin", :FoursquarePlugin, "plugins"),
    LibraryProduct("libPostalCode", :PostalCode, "plugins"),
    LibraryProduct("libOsmPlugin", :OsmPlugin, "plugins"),
    LibraryProduct("libmarblewidget-qt5", :marblewidget),
    LibraryProduct("libNavigationFloatItem", :NavigationFloatItem, "plugins"),
    LibraryProduct("libOverviewMap", :OverviewMap, "plugins"),
    LibraryProduct("libEclipsesPlugin", :EclipsesPlugin, "plugins"),
    LibraryProduct("libLocalDatabasePlugin", :LocalDatabasePlugin, "plugins"),
    ExecutableProduct("marble-qt", :marble_qt),
    LibraryProduct("libPntPlugin", :PntPlugin, "plugins"),
    LibraryProduct("libSpeedometer", :Speedometer, "plugins"),
    LibraryProduct("libLogPlugin", :LogPlugin, "plugins"),
    LibraryProduct("libProgressFloatItem", :ProgressFloatItem, "plugins"),
    LibraryProduct("libNotesPlugin", :NotesPlugin, "plugins"),
    LibraryProduct("libAtmospherePlugin", :AtmospherePlugin, "plugins"),
    LibraryProduct("libCompassFloatItem", :CompassFloatItem, "plugins"),
    LibraryProduct("libOpenRouteServicePlugin", :OpenRouteServicePlugin, "plugins"),
    LibraryProduct("libMapScaleFloatItem", :MapScaleFloatItem, "plugins"),
    LibraryProduct("libmarbledeclarative", :marbledeclarative),
    LibraryProduct("libNominatimReverseGeocodingPlugin", :NominatimReverseGeocodingPlugin, "plugins"),
    LibraryProduct("libMonavPlugin", :MonavPlugin, "plugins"),
    LibraryProduct("libPositionMarker", :PositionMarker, "plugins"),
    LibraryProduct("libEarthquakePlugin", :EarthquakePlugin, "plugins"),
    LibraryProduct("libFlightGearPositionProviderPlugin", :FlightGearPositionProviderPlugin, "plugins"),
    LibraryProduct("libGpsInfo", :GpsInfo, "plugins"),
    LibraryProduct("libCrosshairsPlugin", :CrosshairsPlugin, "plugins"),
    LibraryProduct("libGosmoreReverseGeocodingPlugin", :GosmoreReverseGeocodingPlugin, "plugins"),
    LibraryProduct("libRoutingPlugin", :RoutingPlugin, "plugins"),
    LibraryProduct("libGpsbabelPlugin", :GpsbabelPlugin, "plugins"),
    LibraryProduct("libAprsPlugin", :AprsPlugin, "plugins"),
    LibraryProduct("libGraticulePlugin", :GraticulePlugin, "plugins"),
    LibraryProduct("libSatellitesPlugin", :SatellitesPlugin, "plugins"),
    LibraryProduct("libLatLonPlugin", :LatLonPlugin, "plugins"),
    LibraryProduct("libAnnotatePlugin", :AnnotatePlugin, "plugins"),
    LibraryProduct("libGpxPlugin", :GpxPlugin, "plugins"),
    LibraryProduct("libKmlPlugin", :KmlPlugin, "plugins"),
    LibraryProduct("libSunPlugin", :SunPlugin, "plugins"),
    LibraryProduct("libOSRMPlugin", :OSRMPlugin, "plugins"),
    LibraryProduct("libElevationProfileMarker", :ElevationProfileMarker, "plugins")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Qt_jll", uuid="ede63266-ebff-546c-83e0-1c6fb6d0efc8"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
