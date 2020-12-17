# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "marble"
version = v"20.12.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/KDE/marble/archive/v20.12.0.tar.gz", "20ea52f071bd255109d723565fc46eb46ee4415acb402f5d45f6c6dbd6b312b7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd marble-20.12.0/
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
    LibraryProduct("libCycleStreetsPlugin", :CycleStreetsPlugin, "lib/marble/plugins"),
    LibraryProduct("libNominatimSearchPlugin", :NominatimSearchPlugin, "lib/marble/plugins"),
    LibraryProduct("libPn2Plugin", :Pn2Plugin, "lib/marble/plugins"),
    LibraryProduct("libHostipPlugin", :HostipPlugin, "lib/marble/plugins"),
    LibraryProduct("libStarsPlugin", :StarsPlugin, "lib/marble/plugins"),
    LibraryProduct("libOpenLocationCodeSearchPlugin", :OpenLocationCodeSearchPlugin, "lib/marble/plugins"),
    LibraryProduct("libLicense", :License, "lib/marble/plugins"),
    LibraryProduct("libCachePlugin", :CachePlugin, "lib/marble/plugins"),
    LibraryProduct("libYoursPlugin", :YoursPlugin, "lib/marble/plugins"),
    LibraryProduct("libGosmoreRoutingPlugin", :GosmoreRoutingPlugin, "lib/marble/plugins"),
    LibraryProduct("libElevationProfileFloatItem", :ElevationProfileFloatItem, "lib/marble/plugins"),
    LibraryProduct("libLocalOsmSearchPlugin", :LocalOsmSearchPlugin, "lib/marble/plugins"),
    LibraryProduct("libMapQuestPlugin", :MapQuestPlugin, "lib/marble/plugins"),
    LibraryProduct("libGeoUriPlugin", :GeoUriPlugin, "lib/marble/plugins"),
    LibraryProduct("libRoutinoPlugin", :RoutinoPlugin, "lib/marble/plugins"),
    LibraryProduct("libJsonPlugin", :JsonPlugin, "lib/marble/plugins"),
    LibraryProduct("libMeasureTool", :MeasureTool, "lib/marble/plugins"),
    LibraryProduct("libFoursquarePlugin", :FoursquarePlugin, "lib/marble/plugins"),
    LibraryProduct("libPostalCode", :PostalCode, "lib/marble/plugins"),
    LibraryProduct("libOsmPlugin", :OsmPlugin, "lib/marble/plugins"),
    LibraryProduct("libmarblewidget-qt5", :marblewidget),
    LibraryProduct("libNavigationFloatItem", :NavigationFloatItem, "lib/marble/plugins"),
    LibraryProduct("libOverviewMap", :OverviewMap, "lib/marble/plugins"),
    LibraryProduct("libEclipsesPlugin", :EclipsesPlugin, "lib/marble/plugins"),
    LibraryProduct("libLocalDatabasePlugin", :LocalDatabasePlugin, "lib/marble/plugins"),
    ExecutableProduct("marble-qt", :marble_qt),
    LibraryProduct("libPntPlugin", :PntPlugin, "lib/marble/plugins"),
    LibraryProduct("libSpeedometer", :Speedometer, "lib/marble/plugins"),
    LibraryProduct("libLogPlugin", :LogPlugin, "lib/marble/plugins"),
    LibraryProduct("libProgressFloatItem", :ProgressFloatItem, "lib/marble/plugins"),
    LibraryProduct("libNotesPlugin", :NotesPlugin, "lib/marble/plugins"),
    LibraryProduct("libAtmospherePlugin", :AtmospherePlugin, "lib/marble/plugins"),
    LibraryProduct("libCompassFloatItem", :CompassFloatItem, "lib/marble/plugins"),
    LibraryProduct("libOpenRouteServicePlugin", :OpenRouteServicePlugin, "lib/marble/plugins"),
    LibraryProduct("libMapScaleFloatItem", :MapScaleFloatItem, "lib/marble/plugins"),
    LibraryProduct("libmarbledeclarative", :marbledeclarative),
    LibraryProduct("libNominatimReverseGeocodingPlugin", :NominatimReverseGeocodingPlugin, "lib/marble/plugins"),
    LibraryProduct("libMonavPlugin", :MonavPlugin, "lib/marble/plugins"),
    LibraryProduct("libPositionMarker", :PositionMarker, "lib/marble/plugins"),
    LibraryProduct("libEarthquakePlugin", :EarthquakePlugin, "lib/marble/plugins"),
    LibraryProduct("libFlightGearPositionProviderPlugin", :FlightGearPositionProviderPlugin, "lib/marble/plugins"),
    LibraryProduct("libGpsInfo", :GpsInfo, "lib/marble/plugins"),
    LibraryProduct("libCrosshairsPlugin", :CrosshairsPlugin, "lib/marble/plugins"),
    LibraryProduct("libGosmoreReverseGeocodingPlugin", :GosmoreReverseGeocodingPlugin, "lib/marble/plugins"),
    LibraryProduct("libRoutingPlugin", :RoutingPlugin, "lib/marble/plugins"),
    LibraryProduct("libGpsbabelPlugin", :GpsbabelPlugin, "lib/marble/plugins"),
    LibraryProduct("libAprsPlugin", :AprsPlugin, "lib/marble/plugins"),
    LibraryProduct("libGraticulePlugin", :GraticulePlugin, "lib/marble/plugins"),
    LibraryProduct("libSatellitesPlugin", :SatellitesPlugin, "lib/marble/plugins"),
    LibraryProduct("libLatLonPlugin", :LatLonPlugin, "lib/marble/plugins"),
    LibraryProduct("libAnnotatePlugin", :AnnotatePlugin, "lib/marble/plugins"),
    LibraryProduct("libGpxPlugin", :GpxPlugin, "lib/marble/plugins"),
    LibraryProduct("libKmlPlugin", :KmlPlugin, "lib/marble/plugins"),
    LibraryProduct("libSunPlugin", :SunPlugin, "lib/marble/plugins"),
    LibraryProduct("libOSRMPlugin", :OSRMPlugin, "lib/marble/plugins"),
    LibraryProduct("libElevationProfileMarker", :ElevationProfileMarker, "lib/marble/plugins")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Qt_jll", uuid="ede63266-ebff-546c-83e0-1c6fb6d0efc8"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
