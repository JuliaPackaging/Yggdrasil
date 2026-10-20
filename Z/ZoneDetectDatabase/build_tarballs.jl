using BinaryBuilder, Pkg

name = "ZoneDetectDatabase"
version = v"1.0.0"  # there are no versions upstream; this is made up

sources = [
    GitSource("https://github.com/BertoldVdb/ZoneDetect",
              "082fa6b14815340d0f0d9e23b1ded318ba77c82c"),
    ArchiveSource("https://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_countries_lakes.zip",
                  "3f1596b05b4a19bd97f3a54731497cffbb4dbed4cda494084e73dd6dd3d37264";
                  unpack_target="naturalearth"),
    ArchiveSource("https://github.com/evansiroky/timezone-boundary-builder/releases/download/2026c/timezones-with-oceans.shapefile.zip",
                  "d27714f476799ff57c6c1836df6c910b960f1022af8cfb1cea09c8469f3be2ea";
                  unpack_target="timezone"),
]

# This is adapted from ZoneDetect/database/builder/makedb.sh. Notable deviations:
#  - As of this writing, that file hard-codes evansiroky/timezone-boundary-builder 2024b, but this uses a newer version (see above)
#  - That script downloads the external sources itself, whereas we're using BinaryBuilder-provided mechanisms to download them
#  - We're using `v0` and `v1` under `/share/zonedetect` for output, while the script uses `./out` and `./out_v1`, respectively
#  - We need some additional flags passed to the compiler to ensure it can find shapelib
script = raw"""
cd ${WORKSPACE}/srcdir/ZoneDetect/database/builder

# `builder.cpp` assumes, without checking, that these are in the current directory, so link them here
ln -s ${WORKSPACE}/srcdir/naturalearth ./naturalearth
ln -s ${WORKSPACE}/srcdir/timezone ./timezone

${HOSTCXX} builder.cpp --std=c++11 -o builder -I${host_includedir} -L${host_libdir} -Wl,-rpath=${host_libdir} -lshp

outdir=${WORKSPACE}/destdir/share/zonedetect

for v in 0 1; do
    mkdir -p ${outdir}/v${v}
    for r in 16 21; do
        ./builder C "${WORKSPACE}/srcdir/naturalearth/ne_10m_admin_0_countries_lakes" "${outdir}/v${v}/country${r}.bin" ${r} "Made with Natural Earth, placed in the Public Domain." ${v}
        ./builder T "${WORKSPACE}/srcdir/timezone/combined-shapefile-with-oceans" "${outdir}/v${v}/timezone${r}.bin" ${r} "Contains data from Natural Earth, placed in the Public Domain. Contains information from https://github.com/evansiroky/timezone-boundary-builder, which is made available here under the Open Database License \(ODbL\)." ${v}
    done
done

install_license ../country_DATA_LICENSE ../timezone_DATA_LICENSE
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("share/zonedetect/v0/country16.bin", :country16_v0),
    FileProduct("share/zonedetect/v0/country21.bin", :country21_v0),
    FileProduct("share/zonedetect/v0/timezone16.bin", :timezone16_v0),
    FileProduct("share/zonedetect/v0/timezone21.bin", :timezone21_v0),
    FileProduct("share/zonedetect/v1/country16.bin", :country16_v1),
    FileProduct("share/zonedetect/v1/country21.bin", :country21_v1),
    FileProduct("share/zonedetect/v1/timezone16.bin", :timezone16_v1),
    FileProduct("share/zonedetect/v1/timezone21.bin", :timezone21_v1),
]

dependencies = [
    HostBuildDependency(PackageSpec(; name="ShapeLib_jll", version="1.6.3")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
