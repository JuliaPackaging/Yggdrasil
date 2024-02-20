# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GRASS"
version = v"7.8.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://grass.osgeo.org/grass78/source/grass-$version.tar.gz", "a359bb665524ecccb643335d70f5436b1c84ffb6a0e428b78dffebacd983ff37"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/grass-*/

export LDFLAGS="-L${libdir}"

#patch remove g.proj from general/Makefile for right now, throws a segmentation fault
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # Remove system libexpat to avoid confusion
    rm /usr/lib/libexpat.so*
fi

# Force linking to libiconv with `-liconv`
sed -i 's/ICONVLIB=.*/ICONVLIB=-liconv/' configure

# Need a posix regex for Windows
if [[ "${target}" == *-mingw* ]]; then
    cp "${includedir}/pcreposix.h" "${includedir}/regex.h"
    # Force linking to libregex with `-lpcreposix-0`
    sed -i 's/-lregex/-lpcreposix-0/' configure
fi

./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared \
    --with-python=no \
    --with-cxx \
    --with-lapack --with-lapack-includes=${includedir} \
    --with-tiff --with-tiff-includes=${includedir} \
    --with-png --with-png-includes=${includedir} \
    --with-sqlite --with-sqlite-includes=${includedir} \
    --with-opengl=no \
    --with-fftw --with-fftw-includes=${includedir} \
    --with-cairo --with-cairo-includes=${includedir}/cairo --with-cairo-ldflags=-lfontconfig \
    --with-freetype --with-freetype-includes=${includedir}/freetype2 \
    --with-regex \
    --with-zstd --with-zstd-includes=${includedir} \
    --with-geos=${bindir}/geos-config \
    --with-gdal \
    --with-proj --with-proj-share=${prefix}/share/proj --with-proj-includes=${includedir}

# Build only the libraries
DIRS=(
    include
    tools
    lib/external/shapelib
    lib/datetime
    lib/gis
    lib/linkm
    lib/db
    lib/btree2
    lib/vector
    db/drivers
    lib
    imagery/i.ortho.photo/lib
    vector/v.lrs/lib
    raster/r.li/r.li.daemon
    raster/r.sim/simlib
)

for dir in "${DIRS[@]}"; do
    make -j${nproc} -C "${dir}"
done

# Manually install libraries and header files
cp dist.*/lib/*.${dlext}* ${libdir}/.
cp -r dist.*/include/grass ${includedir}/.

if [[ "${target}" == *-mingw* ]]; then
    # Cover up the traces of the hack
    rm "${includedir}/regex.h"
fi

install_license COPYING GPL.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [

    LibraryProduct(["libgrass_lidar", "libgrass_lidar.7.8"], :libgrass_lidar),
    LibraryProduct(["libgrass_neta", "libgrass_neta.7.8"], :libgrass_neta),
    LibraryProduct(["libgrass_htmldriver", "libgrass_htmldriver.7.8"], :libgrass_htmldriver),
    LibraryProduct(["libgrass_cluster", "libgrass_cluster.7.8"], :libgrass_cluster),
    LibraryProduct(["libgrass_gmath", "libgrass_gmath.7.8"], :libgrass_gmath),
    LibraryProduct(["libgrass_interpdata", "libgrass_interpdata.7.8"], :libgrass_interpdata),
    LibraryProduct(["libgrass_psdriver", "libgrass_psdriver.7.8"], :libgrass_psdriver),
    LibraryProduct(["libgrass_pngdriver", "libgrass_pngdriver.7.8"], :libgrass_pngdriver),
    LibraryProduct(["libgrass_dspf", "libgrass_dspf.7.8"], :libgrass_dspf),
    LibraryProduct(["libgrass_bitmap", "libgrass_bitmap.7.8"], :libgrass_bitmap),
    LibraryProduct(["libgrass_shape", "libgrass_shape.7.8"], :libgrass_shape),
    LibraryProduct(["libgrass_rtree", "libgrass_rtree.7.8"], :libgrass_rtree),
    LibraryProduct(["libgrass_cairodriver", "libgrass_cairodriver.7.8"], :libgrass_cairodriver),
    LibraryProduct(["libgrass_rowio", "libgrass_rowio.7.8"], :libgrass_rowio),
    LibraryProduct(["libgrass_lrs", "libgrass_lrs.7.8"], :libgrass_lrs),
    LibraryProduct(["libgrass_qtree", "libgrass_qtree.7.8"], :libgrass_qtree),
    LibraryProduct(["libgrass_gis", "libgrass_gis.7.8"], :libgrass_gis),
    LibraryProduct(["libgrass_gpde", "libgrass_gpde.7.8"], :libgrass_gpde),
    LibraryProduct(["libgrass_vector", "libgrass_vector.7.8"], :libgrass_vector),
    LibraryProduct(["libgrass_segment", "libgrass_segment.7.8"], :libgrass_segment),
    LibraryProduct(["libgrass_g3d", "libgrass_g3d.7.8"], :libgrass_g3d),
    LibraryProduct(["libgrass_display", "libgrass_display.7.8"], :libgrass_display),
    LibraryProduct(["libgrass_iortho", "libgrass_iortho.7.8"], :libgrass_iortho),
    LibraryProduct(["libgrass_btree2", "libgrass_btree2.7.8"], :libgrass_btree2),
    LibraryProduct(["libgrass_imagery", "libgrass_imagery.7.8"], :libgrass_imagery),
    LibraryProduct(["libgrass_datetime", "libgrass_datetime.7.8"], :libgrass_datetime),
    LibraryProduct(["libgrass_linkm", "libgrass_linkm.7.8"], :libgrass_linkm),
    LibraryProduct(["libgrass_ccmath", "libgrass_ccmath.7.8"], :libgrass_ccmath),
    LibraryProduct(["libgrass_driver", "libgrass_driver.7.8"], :libgrass_driver),
    LibraryProduct(["libgrass_gproj", "libgrass_gproj.7.8"], :libgrass_gproj),
    LibraryProduct(["libgrass_dgl", "libgrass_dgl.7.8"], :libgrass_dgl),
    LibraryProduct(["libgrass_dbmibase", "libgrass_dbmibase.7.8"], :libgrass_dbmibase),
    LibraryProduct(["libgrass_stats", "libgrass_stats.7.8"], :libgrass_stats),
    LibraryProduct(["libgrass_temporal", "libgrass_temporal.7.8"], :libgrass_temporal),
    LibraryProduct(["libgrass_sim", "libgrass_sim.7.8"], :libgrass_sim),
    LibraryProduct(["libgrass_btree", "libgrass_btree.7.8"], :libgrass_btree),
    LibraryProduct(["libgrass_dbstubs", "libgrass_dbstubs.7.8"], :libgrass_dbstubs),
    LibraryProduct(["libgrass_vedit", "libgrass_vedit.7.8"], :libgrass_vedit),
    LibraryProduct(["libgrass_calc", "libgrass_calc.7.8"], :libgrass_calc),
    LibraryProduct(["libgrass_raster", "libgrass_raster.7.8"], :libgrass_raster),
    LibraryProduct(["libgrass_cdhc", "libgrass_cdhc.7.8"], :libgrass_cdhc),
    LibraryProduct(["libgrass_interpfl", "libgrass_interpfl.7.8"], :libgrass_interpfl),
    LibraryProduct(["libgrass_dbmidriver", "libgrass_dbmidriver.7.8"], :libgrass_dbmidriver),
    LibraryProduct(["libgrass_rli", "libgrass_rli.7.8"], :libgrass_rli),
    LibraryProduct(["libgrass_arraystats", "libgrass_arraystats.7.8"], :libgrass_arraystats),
    LibraryProduct(["libgrass_sqlp", "libgrass_sqlp.7.8"], :libgrass_sqlp),
    LibraryProduct(["libgrass_dig2", "libgrass_dig2.7.8"], :libgrass_dig2),
    LibraryProduct(["libgrass_symb", "libgrass_symb.7.8"], :libgrass_symb),
    LibraryProduct(["libgrass_dbmiclient", "libgrass_dbmiclient.7.8"], :libgrass_dbmiclient),
    LibraryProduct(["libgrass_manage", "libgrass_manage.7.8"], :libgrass_manage),

    # ExecutableProduct("g.mkfontcap", :g_mkfontcap, "grass78/bin"),
    # ExecutableProduct("g.region", :g_region, "grass78/bin"),
    # ExecutableProduct("g.ppmtopng", :g_ppmtopng, "grass78/bin"),
    # ExecutableProduct("g.dirseps", :g_dirseps, "grass78/bin"),
    # ExecutableProduct("g.parser", :g_parser, "grass78/bin"),
    # ExecutableProduct("g.message", :g_message, "grass78/bin"),
    # ExecutableProduct("g.copy", :g_copy, "grass78/bin"),
    # ExecutableProduct("g.access", :g_access, "grass78/bin"),
    # ExecutableProduct("g.mapsets", :g_mapsets, "grass78/bin"),
    # ExecutableProduct("g.tempfile", :g_tempfile, "grass78/bin"),
    # ExecutableProduct("g.rename", :g_rename, "grass78/bin"),
    # ExecutableProduct("g.findfile", :g_findfile, "grass78/bin"),
    # ExecutableProduct("g.remove", :g_remove, "grass78/bin"),
    # ExecutableProduct("g.gui", :g_gui, "grass78/bin"),
    # ExecutableProduct("g.findetc", :g_findetc, "grass78/bin"),
    # ExecutableProduct("g.version", :g_version, "grass78/bin"),
    # ExecutableProduct("g.list", :g_list, "grass78/bin"),
    # ExecutableProduct("g.filename", :g_filename, "grass78/bin"),
    # ExecutableProduct("g.mapset", :g_mapset, "grass78/bin"),
    # ExecutableProduct("g.echo", :g_echo, "grass78/tools"),
    # ExecutableProduct("g.pnmcomp", :g_pnmcomp, "grass78/bin"),
    # ExecutableProduct("g.gisenv", :g_gisenv, "grass78/bin"),

    # ExecutableProduct("db.createdb", :db_createdb, "grass78/bin"),
    # ExecutableProduct("db.login", :db_login, "grass78/bin"),
    # ExecutableProduct("db.connect", :db_connect, "grass78/bin"),
    # ExecutableProduct("db.execute", :db_execute, "grass78/bin"),
    # ExecutableProduct("db.databases", :db_databases, "grass78/bin"),
    # ExecutableProduct("db.tables", :db_tables, "grass78/bin"),
    # ExecutableProduct("db.describe", :db_describe, "grass78/bin"),
    # ExecutableProduct("db.columns", :db_columns, "grass78/bin"),
    # ExecutableProduct("db.copy", :db_copy, "grass78/bin"),
    # ExecutableProduct("db.dropdb", :db_dropdb, "grass78/bin"),
    # ExecutableProduct("db.select", :db_select, "grass78/bin"),
    # ExecutableProduct("db.drivers", :db_drivers, "grass78/bin"),

    # ExecutableProduct("r.statistics", :r_statistics, "grass78/bin"),
    # ExecutableProduct("r.sim.water", :r_sim_water, "grass78/bin"),
    # ExecutableProduct("r.volume", :r_volume, "grass78/bin"),
    # ExecutableProduct("r.carve", :r_carve, "grass78/bin"),
    # ExecutableProduct("r.basins.fill", :r_basins_fill, "grass78/bin"),
    # ExecutableProduct("r.param.scale", :r_params_scale, "grass78/bin"),
    # ExecutableProduct("r.to.rast3elev", :r_to_rast3elev, "grass78/bin"),
    # ExecutableProduct("r.out.vrml", :r_out_vrml, "grass78/bin"),
    # ExecutableProduct("r.mapcalc", :r_mapcalc, "grass78/bin"),
    # ExecutableProduct("r.resample", :r_resample, "grass78/bin"),
    # ExecutableProduct("r.stream.extract", :r_stream_extract, "grass78/bin"),
    # ExecutableProduct("r.out.mat", :r_out_mat, "grass78/bin"),
    # ExecutableProduct("r.external", :r_external, "grass78/bin"),
    # ExecutableProduct("r.cost", :r_cost, "grass78/bin"),
    # ExecutableProduct("r.series", :r_series, "grass78/bin"),
    # ExecutableProduct("r.cross", :r_cross, "grass78/bin"),
    # ExecutableProduct("r.category", :r_category, "grass78/bin"),
    # ExecutableProduct("r.buffer", :r_buffer, "grass78/bin"),
    # ExecutableProduct("r.surf.contour", :r_surf_contour, "grass78/bin"),
    # ExecutableProduct("r.topmodel", :r_topmodel, "grass78/bin"),
    # ExecutableProduct("r.watershed", :r_watershed, "grass78/bin"),
    # ExecutableProduct("r.support", :r_support, "grass78/bin"),
    # ExecutableProduct("r.li.padsd", :r_li_padsd, "grass78/bin"),
    # ExecutableProduct("r.random.cells", :r_random_cells, "grass78/bin"),
    # ExecutableProduct("r.sunhours", :r_sunhours, "grass78/bin"),
    # ExecutableProduct("r.out.ppm3", :r_out_ppm3, "grass78/bin"),
    # ExecutableProduct("r.li.richness", :r_li_richness, "grass78/bin"),
    # ExecutableProduct("r.li.dominance", :r_li_dominance, "grass78/bin"),
    # ExecutableProduct("r.patch", :r_patch, "grass78/bin"),
    # ExecutableProduct("r.water.outlet", :r_water_outlet, "grass78/bin"),
    # ExecutableProduct("r.regression.multi", :r_regression_multi, "grass78/bin"),
    # ExecutableProduct("r.out.ascii", :r_out_ascii, "grass78/bin"),
    # ExecutableProduct("r.what.color", :r_what_color, "grass78/bin"),
    # ExecutableProduct("r.profile", :r_profile, "grass78/bin"),
    # ExecutableProduct("r.rescale.eq", :r_rescale_eq, "grass78/bin"),
    # ExecutableProduct("r.terraflow", :r_terraflow, "grass78/bin"),
    # ExecutableProduct("r.colors", :r_colors, "grass78/bin"),
    # ExecutableProduct("r.li.cwed", :r_li_cwed, "grass78/bin"),
    # ExecutableProduct("r.univar", :r_univar, "grass78/bin"),
    # ExecutableProduct("r.mode", :r_mode, "grass78/bin"),
    # ExecutableProduct("r.distance", :r_distance, "grass78/bin"),
    # ExecutableProduct("r.thin", :r_thin, "grass78/bin"),
    # ExecutableProduct("r.viewshed", :r_viewshed, "grass78/bin"),
    # ExecutableProduct("r.null", :r_null, "grass78/bin"),
    # ExecutableProduct("r.rescale", :r_rescale, "grass78/bin"),
    # ExecutableProduct("r.surf.area", :r_surf_area, "grass78/bin"),
    # ExecutableProduct("r.reclass", :r_reclass, "grass78/bin"),
    # ExecutableProduct("r.in.bin", :r_in_bin, "grass78/bin"),
    # ExecutableProduct("r.geomorphon", :r_geomorphon, "grass78/bin"),
    # ExecutableProduct("r.his", :r_his, "grass78/bin"),
    # ExecutableProduct("r.stats.quantile", :r_stats_quantile, "grass78/bin"),
    # ExecutableProduct("r.out.vtk", :r_out_vtk, "grass78/bin"),
    # ExecutableProduct("r.walk", :r_walk, "grass78/bin"),
    # ExecutableProduct("r.gwflow", :r_gwflow, "grass78/bin"),
    # ExecutableProduct("r.li.edgedensity", :r_li_edgedensity, "grass78/bin"),
    # ExecutableProduct("r.texture", :r_texture, "grass78/bin"),
    # ExecutableProduct("r.resamp.stats", :r_resamp_stats, "grass78/bin"),
    # ExecutableProduct("r.fill.stats", :r_fill_stats, "grass78/bin"),
    # ExecutableProduct("r.li.shannon", :r_li_shannon, "grass78/bin"),
    # ExecutableProduct("r.in.gdal", :r_in_gdal, "grass78/bin"),
    # ExecutableProduct("r.buildvrt", :r_buildvrt, "grass78/bin"),
    # ExecutableProduct("r.grow.distance", :r_grow_distance, "grass78/bin"),
    # ExecutableProduct("r.circle", :r_circle, "grass78/bin"),
    # ExecutableProduct("r.in.png", :r_in_png, "grass78/bin"),
    # ExecutableProduct("r.li.padrange", :r_li_padrange, "grass78/bin"),
    # ExecutableProduct("r.spread", :r_spread, "grass78/bin"),
    # ExecutableProduct("r.out.gridatb", :r_out_gridatb, "grass78/bin"),
    # ExecutableProduct("r.info", :r_info, "grass78/bin"),
    # ExecutableProduct("r.clump", :r_clump, "grass78/bin"),
    # ExecutableProduct("r.li.pielou", :r_li_pielou, "grass78/bin"),
    # ExecutableProduct("r.resamp.filter", :r_resamp_filter, "grass78/bin"),
    # ExecutableProduct("r.surf.fractal", :r_surf_fractal, "grass78/bin"),
    # ExecutableProduct("r.timestamp", :r_timestamp, "grass78/bin"),
    # ExecutableProduct("r.in.xyz", :r_in_xyz, "grass78/bin"),
    # ExecutableProduct("r.li.padcv", :r_li_padcv, "grass78/bin"),
    # ExecutableProduct("r.solute.transport", :r_solute_transport, "grass78/bin"),
    # ExecutableProduct("r.in.poly", :r_in_poly, "grass78/bin"),
    # ExecutableProduct("r.out.bin", :r_out_bin, "grass78/bin"),
    # ExecutableProduct("r.compress", :r_compress, "grass78/bin"),
    # ExecutableProduct("r.region", :r_region, "grass78/bin"),
    # ExecutableProduct("r.surf.gauss", :r_surf_gauss, "grass78/bin"),
    # ExecutableProduct("r.recode", :r_recode, "grass78/bin"),
    # ExecutableProduct("r.ros", :r_ros, "grass78/bin"),
    # ExecutableProduct("r.latlong", :r_latlong, "grass78/bin"),
    # ExecutableProduct("r.tile", :r_tile, "grass78/bin"),
    # ExecutableProduct("r.quantile", :r_quantile, "grass78/bin"),
    # ExecutableProduct("r.resamp.rst", :r_resamp_rst, "grass78/bin"),
    # ExecutableProduct("r.topidx", :r_topidx, "grass78/bin"),
    # ExecutableProduct("r.lake", :r_lake, "grass78/bin"),
    # ExecutableProduct("r.composite", :r_composite, "grass78/bin"),
    # ExecutableProduct("r.kappa", :r_kappa, "grass78/bin"),
    # ExecutableProduct("r.li.mpa", :r_li_mpa, "grass78/bin"),
    # ExecutableProduct("r.out.ppm", :r_out_ppm, "grass78/bin"),
    # ExecutableProduct("r.sunmask", :r_sunmask, "grass78/bin"),
    # ExecutableProduct("r.to.vect", :r_to_vect, "grass78/bin"),
    # ExecutableProduct("r.random.surface", :r_random_surface, "grass78/bin"),
    # ExecutableProduct("r.li.simpson", :r_li_simpson, "grass78/bin"),
    # ExecutableProduct("r.out.pov", :r_out_pov, "grass78/bin"),
    # ExecutableProduct("r.what", :r_what, "grass78/bin"),
    # ExecutableProduct("r.li.patchdensity", :r_li_patchdensity, "grass78/bin"),
    # ExecutableProduct("r.flow", :r_flow, "grass78/bin"),
    # ExecutableProduct("r.surf.idw", :r_surf_idw, "grass78/bin"),
    # ExecutableProduct("r.spreadpath", :r_spreadpath, "grass78/bin"),
    # ExecutableProduct("r.fill.dir", :r_fill_dir, "grass78/bin"),
    # ExecutableProduct("r.in.ascii", :r_in_ascii, "grass78/bin"),
    # ExecutableProduct("r.resamp.bspline", :r_resamp_bspline, "grass78/bin"),
    # ExecutableProduct("r.uslek", :r_uslek, "grass78/bin"),
    # ExecutableProduct("r.mfilter", :r_mfilter, "grass78/bin"),
    # ExecutableProduct("r.series.accumulate", :r_series_accumulate, "grass78/bin"),
    # ExecutableProduct("r.stats.zonal", :r_stats_zonal, "grass78/bin"),
    # ExecutableProduct("r.li.shape", :r_li_shape, "grass78/bin"),
    # ExecutableProduct("r.regression.line", :r_regression_line, "grass78/bin"),
    # ExecutableProduct("r.sim.sediment", :r_sim_sediment, "grass78/bin"),
    # ExecutableProduct("r.transect", :r_transect, "grass78/bin"),
    # ExecutableProduct("r.in.gridatb", :r_in_gridatb, "grass78/bin"),
    # ExecutableProduct("r.coin", :r_coin, "grass78/bin"),
    # ExecutableProduct("r.slope.aspect", :r_slope_aspect, "grass78/bin"),
    # ExecutableProduct("r.covar", :r_covar, "grass78/bin"),
    # ExecutableProduct("r.horizon", :r_horizon, "grass78/bin"),
    # ExecutableProduct("r.out.png", :r_out_png, "grass78/bin"),
    # ExecutableProduct("r.neighbors", :r_neighbors, "grass78/bin"),
    # ExecutableProduct("r.li.mps", :r_li_mps, "grass78/bin"),
    # ExecutableProduct("r.contour", :r_contour, "grass78/bin"),
    # ExecutableProduct("r.in.mat", :r_in_mat, "grass78/bin"),
    # ExecutableProduct("r.relief", :r_relief, "grass78/bin"),
    # ExecutableProduct("r.path", :r_path, "grass78/bin"),
    # ExecutableProduct("r.series.interp", :r_series_interp, "grass78/bin"),
    # ExecutableProduct("r.proj", :r_proj, "grass78/bin"),
    # ExecutableProduct("r.li.patchnum", :r_li_patchnum, "grass78/bin"),
    # ExecutableProduct("r.usler", :r_usler, "grass78/bin"),
    # ExecutableProduct("r.to.rast3", :r_to_rast3, "grass78/bin"),
    # ExecutableProduct("r.quant", :r_quant, "grass78/bin"),
    # ExecutableProduct("r.report", :r_report, "grass78/bin"),
    # ExecutableProduct("r.colors.out", :r_colors_out, "grass78/bin"),
    # ExecutableProduct("r.support.stats", :r_support_stats, "grass78/bin"),
    # ExecutableProduct("r.li.renyi", :r_li_renyi, "grass78/bin"),
    # ExecutableProduct("r.external.out", :r_external_out, "grass78/bin"),
    # ExecutableProduct("r.random", :r_random, "grass78/bin"),
    # ExecutableProduct("r.stats", :r_stats, "grass78/bin"),
    # ExecutableProduct("r.surf.random", :r_surf_random, "grass78/bin"),
    # ExecutableProduct("r.resamp.interp", :r_resamp_interp, "grass78/bin"),
    # ExecutableProduct("r.sun", :r_sun, "grass78/bin"),
    # ExecutableProduct("r.describe", :r_describe, "grass78/bin"),
    # ExecutableProduct("r.out.gdal", :r_out_gdal, "grass78/bin"),
    # ExecutableProduct("r.out.mpeg", :r_out_mpeg, "grass78/bin"),

    # ExecutableProduct("v.in.db", :v_in_db, "grass78/bin"),
    # ExecutableProduct("v.lidar.growing", :v_lidar_growing, "grass78/bin"),
    # ExecutableProduct("v.out.vtk", :v_out_vtk, "grass78/bin"),
    # ExecutableProduct("v.surf.bspline", :v_surf_bspline, "grass78/bin"),
    # ExecutableProduct("v.net.distance", :v_net_distance, "grass78/bin"),
    # ExecutableProduct("v.support", :v_support, "grass78/bin"),
    # ExecutableProduct("v.univar", :v_univar, "grass78/bin"),
    # ExecutableProduct("v.out.ascii", :v_out_ascii, "grass78/bin"),
    # ExecutableProduct("v.reclass", :v_reclass, "grass78/bin"),
    # ExecutableProduct("v.surf.idw", :v_surf_idw, "grass78/bin"),
    # ExecutableProduct("v.net.visibility", :v_net_visibility, "grass78/bin"),
    # ExecutableProduct("v.build.polylines", :v_build_polylines, "grass78/bin"),
    # ExecutableProduct("v.outlier", :v_outlier, "grass78/bin"),
    # ExecutableProduct("v.split", :v_split, "grass78/bin"),
    # ExecutableProduct("v.vol.rst", :v_vol_rst, "grass78/bin"),
    # ExecutableProduct("v.parallel", :v_parallel, "grass78/bin"),
    # ExecutableProduct("v.net.steiner", :v_net_steiner, "grass78/bin"),
    # ExecutableProduct("v.net.path", :v_net_path, "grass78/bin"),
    # ExecutableProduct("v.transform", :v_transform, "grass78/bin"),
    # ExecutableProduct("v.kcv", :v_kcv, "grass78/bin"),
    # ExecutableProduct("v.category", :v_category, "grass78/bin"),
    # ExecutableProduct("v.profile", :v_profile, "grass78/bin"),
    # ExecutableProduct("v.drape", :v_drape, "grass78/bin"),
    # ExecutableProduct("v.out.ogr", :v_out_ogr, "grass78/bin"),
    # ExecutableProduct("v.db.select", :v_db_select, "grass78/bin"),
    # ExecutableProduct("v.what.rast", :v_what_rast, "grass78/bin"),
    # ExecutableProduct("v.neighbors", :v_neighbors, "grass78/bin"),
    # ExecutableProduct("v.net.salesman", :v_net_salesman, "grass78/bin"),
    # ExecutableProduct("v.normal", :v_normal, "grass78/bin"),
    # ExecutableProduct("v.in.dxf", :v_in_dxf, "grass78/bin"),
    # ExecutableProduct("v.colors", :v_colors, "grass78/bin"),
    # ExecutableProduct("v.perturb", :v_perturb, "grass78/bin"),
    # ExecutableProduct("v.decimate", :v_decimate, "grass78/bin"),
    # ExecutableProduct("v.extrude", :v_extrude, "grass78/bin"),
    # ExecutableProduct("v.to.db", :v_to_db, "grass78/bin"),
    # ExecutableProduct("v.kernel", :v_kernel, "grass78/bin"),
    # ExecutableProduct("v.random", :v_random, "grass78/bin"),
    # ExecutableProduct("v.net.flow", :v_net_flow, "grass78/bin"),
    # ExecutableProduct("v.lrs.segment", :v_lrs_segment, "grass78/bin"),
    # ExecutableProduct("v.label", :v_label, "grass78/bin"),
    # ExecutableProduct("v.lrs.create", :v_lrs_create, "grass78/bin"),
    # ExecutableProduct("v.mkgrid", :v_mkgrid, "grass78/bin"),
    # ExecutableProduct("v.generalize", :v_generalize, "grass78/bin"),
    # ExecutableProduct("v.net.alloc", :v_net_alloc, "grass78/bin"),
    # ExecutableProduct("v.vect.stats", :v_vect_stats, "grass78/bin"),
    # ExecutableProduct("v.in.ogr", :v_in_ogr, "grass78/bin"),
    # ExecutableProduct("v.lrs.label", :v_lrs_label, "grass78/bin"),
    # ExecutableProduct("v.to.points", :v_to_points, "grass78/bin"),
    # ExecutableProduct("v.lidar.edgedetection", :v_lidar_edgedetection, "grass78/bin"),
    # ExecutableProduct("v.out.pov", :v_out_pov, "grass78/bin"),
    # ExecutableProduct("v.db.connect", :v_db_connect, "grass78/bin"),
    # ExecutableProduct("v.colors.out", :v_colors_out, "grass78/bin"),
    # ExecutableProduct("v.distance", :v_distance, "grass78/bin"),
    # ExecutableProduct("v.sample", :v_sample, "grass78/bin"),
    # ExecutableProduct("v.timestamp", :v_timestamp, "grass78/bin"),
    # ExecutableProduct("v.what", :v_what, "grass78/bin"),
    # ExecutableProduct("v.extract", :v_extract, "grass78/bin"),
    # ExecutableProduct("v.buffer", :v_buffer, "grass78/bin"),
    # ExecutableProduct("v.net.iso", :v_net_iso, "grass78/bin"),
    # ExecutableProduct("v.net.components", :v_net_components, "grass78/bin"),
    # ExecutableProduct("v.net.centrality", :v_net_centrality, "grass78/bin"),
    # ExecutableProduct("v.surf.rst", :v_surf_rst, "grass78/bin"),
    # ExecutableProduct("v.to.3d", :v_to_3d, "grass78/bin"),
    # ExecutableProduct("v.qcount", :v_qcount, "grass78/bin"),
    # ExecutableProduct("v.edit", :v_edit, "grass78/bin"),
    # ExecutableProduct("v.rectify", :v_rectify, "grass78/bin"),
    # ExecutableProduct("v.label.sa", :v_label_sa, "grass78/bin"),
    # ExecutableProduct("v.net.allpairs", :v_net_allpairs, "grass78/bin"),
    # ExecutableProduct("v.external.out", :v_external_out, "grass78/bin"),
    # ExecutableProduct("v.what.rast3", :v_what_rast3, "grass78/bin"),
    # ExecutableProduct("v.in.ascii", :v_in_ascii, "grass78/bin"),
    # ExecutableProduct("v.patch", :v_patch, "grass78/bin"),
    # ExecutableProduct("v.clean", :v_clean, "grass78/bin"),
    # ExecutableProduct("v.info", :v_info, "grass78/bin"),
    # ExecutableProduct("v.net.timetable", :v_net_timetable, "grass78/bin"),
    # ExecutableProduct("v.net.bridge", :v_net_bridge, "grass78/bin"),
    # ExecutableProduct("v.out.dxf", :v_out_dxf, "grass78/bin"),
    # ExecutableProduct("v.to.rast", :v_to_rast, "grass78/bin"),
    # ExecutableProduct("v.lrs.where", :v_lrs_where, "grass78/bin"),
    # ExecutableProduct("v.delaunay", :v_delaunay, "grass78/bin"),
    # ExecutableProduct("v.in.region", :v_in_region, "grass78/bin"),
    # ExecutableProduct("v.external", :v_external, "grass78/bin"),
    # ExecutableProduct("v.lidar.correction", :v_lidar_correction, "grass78/bin"),
    # ExecutableProduct("v.class", :v_class, "grass78/bin"),
    # ExecutableProduct("v.segment", :v_segment, "grass78/bin"),
    # ExecutableProduct("v.proj", :v_proj, "grass78/bin"),
    # ExecutableProduct("v.cluster", :v_cluster, "grass78/bin"),
    # ExecutableProduct("v.overlay", :v_overlay, "grass78/bin"),
    # ExecutableProduct("v.type", :v_type, "grass78/bin"),
    # ExecutableProduct("v.voronoi", :v_voronoi, "grass78/bin"),
    # ExecutableProduct("v.hull", :v_hull, "grass78/bin"),
    # ExecutableProduct("v.out.svg", :v_out_svg, "grass78/bin"),
    # ExecutableProduct("v.net.connectivity", :v_net_connectivity, "grass78/bin"),
    # ExecutableProduct("v.build", :v_build, "grass78/bin"),
    # ExecutableProduct("v.net.spanningtree", :v_net_spanningtree, "grass78/bin"),
    # ExecutableProduct("v.net", :v_net, "grass78/bin"),
    # ExecutableProduct("v.to.rast3", :v_to_rast3, "grass78/bin"),
    # ExecutableProduct("v.select", :v_select, "grass78/bin"),

    # ExecutableProduct("i.atcorr", :i_atcorr, "grass78/bin"),
    # ExecutableProduct("i.eb.hsebal01", :i_eb_hsebal01, "grass78/bin"),
    # ExecutableProduct("i.ifft", :i_ifft, "grass78/bin"),
    # ExecutableProduct("i.biomass", :i_biomass, "grass78/bin"),
    # ExecutableProduct("i.gensig", :i_gensig, "grass78/bin"),
    # ExecutableProduct("i.eb.soilheatflux", :i_eb_soilheatflux, "grass78/bin"),
    # ExecutableProduct("i.albedo", :i_albedo, "grass78/bin"),
    # ExecutableProduct("i.evapo.mh", :i_evapo_mh, "grass78/bin"),
    # ExecutableProduct("i.eb.eta", :i_eb_eta, "grass78/bin"),
    # ExecutableProduct("i.aster.toar", :i_aster_toar, "grass78/bin"),
    # ExecutableProduct("i.target", :i_target, "grass78/bin"),
    # ExecutableProduct("i.rgb.his", :i_rgb_his, "grass78/bin"),
    # ExecutableProduct("i.evapo.pt", :i_evapo_pt, "grass78/bin"),
    # ExecutableProduct("i.find", :i_find, "grass78/etc"),
    # ExecutableProduct("i.ortho.camera", :i_ortho_camera, "grass78/bin"),
    # ExecutableProduct("i.evapo.pm", :i_evapo_pm, "grass78/bin"),
    # ExecutableProduct("i.eb.evapfr", :i_eb_evapfr, "grass78/bin"),
    # ExecutableProduct("i.ortho.elev", :i_ortho_elev, "grass78/bin"),
    # ExecutableProduct("i.group", :i_group, "grass78/bin"),
    # ExecutableProduct("i.ortho.rectify", :i_ortho_rectify, "grass78/bin"),
    # ExecutableProduct("i.ortho.init", :i_ortho_init, "grass78/bin"),
    # ExecutableProduct("i.eb.netrad", :i_eb_netrad, "grass78/bin"),
    # ExecutableProduct("i.segment", :i_segment, "grass78/bin"),
    # ExecutableProduct("i.vi", :i_vi, "grass78/bin"),
    # ExecutableProduct("i.maxlik", :i_maxlik, "grass78/bin"),
    # ExecutableProduct("i.evapo.time", :i_evapo_time, "grass78/bin"),
    # ExecutableProduct("i.ortho.transform", :i_ortho_transform, "grass78/bin"),
    # ExecutableProduct("i.topo.corr", :i_topo_corr, "grass78/bin"),
    # ExecutableProduct("i.modis.qc", :i_modis_qc, "grass78/bin"),
    # ExecutableProduct("i.cca", :i_cca, "grass78/bin"),
    # ExecutableProduct("i.his.rgb", :i_his_rgb, "grass78/bin"),
    # ExecutableProduct("i.fft", :i_fft, "grass78/bin"),
    # ExecutableProduct("i.landsat.toar", :i_landsat_toar, "grass78/bin"),
    # ExecutableProduct("i.gensigset", :i_gensigset, "grass78/bin"),
    # ExecutableProduct("i.rectify", :i_rectify, "grass78/bin"),
    # ExecutableProduct("i.pca", :i_pca, "grass78/bin"),
    # ExecutableProduct("i.emissivity", :i_emissivity, "grass78/bin"),
    # ExecutableProduct("i.landsat.acca", :i_landsat_acca, "grass78/bin"),
    # ExecutableProduct("i.zc", :i_zc, "grass78/bin"),
    # ExecutableProduct("i.ortho.photo", :i_ortho_photo, "grass78/bin"),
    # ExecutableProduct("i.smap", :i_smap, "grass78/bin"),
    # ExecutableProduct("i.cluster", :i_cluster, "grass78/bin"),
    # ExecutableProduct("i.ortho.target", :i_ortho_target, "grass78/bin"),

    # ExecutableProduct("r3.in.ascii", :r3_in_ascii, "grass78/bin"),
    # ExecutableProduct("r3.in.bin", :r3_in_bin, "grass78/bin"),
    # ExecutableProduct("r3.to.rast", :r3_to_rast, "grass78/bin"),
    # ExecutableProduct("r3.timestamp", :r3_timestamp, "grass78/bin"),
    # ExecutableProduct("r3.support", :r3_support, "grass78/bin"),
    # ExecutableProduct("r3.retile", :r3_retile, "grass78/bin"),
    # ExecutableProduct("r3.colors.out", :r3_colors_out, "grass78/bin"),
    # ExecutableProduct("r3.out.vtk", :r3_out_vtk, "grass78/bin"),
    # ExecutableProduct("r3.in.v5d", :r3_in_v5d, "grass78/bin"),
    # ExecutableProduct("r3.mapcalc", :r3_mapcalc, "grass78/bin"),
    # ExecutableProduct("r3.info", :r3_info, "grass78/bin"),
    # ExecutableProduct("r3.flow", :r3_flow, "grass78/bin"),
    # ExecutableProduct("r3.neighbors", :r3_neighbors, "grass78/bin"),
    # ExecutableProduct("r3.out.ascii", :r3_out_ascii, "grass78/bin"),
    # ExecutableProduct("r3.gwflow", :r3_gwflow, "grass78/bin"),
    # ExecutableProduct("r3.mask", :r3_mask, "grass78/bin"),
    # ExecutableProduct("r3.null", :r3_null, "grass78/bin"),
    # ExecutableProduct("r3.out.v5d", :r3_out_v5d, "grass78/bin"),
    # ExecutableProduct("r3.out.bin", :r3_out_bin, "grass78/bin"),
    # ExecutableProduct("r3.colors", :r3_colors, "grass78/bin"),
    # ExecutableProduct("r3.mkdspf", :r3_mkdspf, "grass78/bin"),
    # ExecutableProduct("r3.gradient", :r3_gradient, "grass78/bin"),
    # ExecutableProduct("r3.univar", :r3_univar, "grass78/bin"),
    # ExecutableProduct("r3.stats", :r3_stats, "grass78/bin"),
    # ExecutableProduct("r3.cross.rast", :r3_cross_rast, "grass78/bin"),

    # ExecutableProduct("d.info", :d_info, "grass78/bin"),
    # ExecutableProduct("d.rast.num", :d_rast_num, "grass78/bin"),
    # ExecutableProduct("d.text", :d_text, "grass78/bin"),
    # ExecutableProduct("d.barscale", :d_barscale, "grass78/bin"),
    # ExecutableProduct("d.rast.arrow", :d_rast_arrow, "grass78/bin"),
    # ExecutableProduct("d.font", :d_font, "grass78/bin"),
    # ExecutableProduct("d.geodesic", :d_geodesic, "grass78/bin"),
    # ExecutableProduct("d.rhumbline", :d_rhumbline, "grass78/bin"),
    # ExecutableProduct("d.vect", :d_vect, "grass78/bin"),
    # ExecutableProduct("d.northarrow", :d_northarrow, "grass78/bin"),
    # ExecutableProduct("d.linegraph", :d_linegraph, "grass78/bin"),
    # ExecutableProduct("d.path", :d_path, "grass78/bin"),
    # ExecutableProduct("d.where", :d_where, "grass78/bin"),
    # ExecutableProduct("d.vect.thematic", :d_vect_thematic, "grass78/bin"),
    # ExecutableProduct("d.fontlist", :d_fontlist, "grass78/bin"),
    # ExecutableProduct("d.vect.chart", :d_vect_chart, "grass78/bin"),
    # ExecutableProduct("d.mon", :d_mon, "grass78/bin"),
    # ExecutableProduct("d.legend.vect", :d_legend_vect, "grass78/bin"),
    # ExecutableProduct("d.erase", :d_erase, "grass78/bin"),
    # ExecutableProduct("d.labels", :d_labels, "grass78/bin"),
    # ExecutableProduct("d.histogram", :d_histogram, "grass78/bin"),
    # ExecutableProduct("d.colorlist", :d_colorlist, "grass78/bin"),
    # ExecutableProduct("d.his", :d_his, "grass78/bin"),
    # ExecutableProduct("d.title", :d_title, "grass78/bin"),
    # ExecutableProduct("d.profile", :d_profile, "grass78/bin"),
    # ExecutableProduct("d.grid", :d_grid, "grass78/bin"),
    # ExecutableProduct("d.rgb", :d_rgb, "grass78/bin"),
    # ExecutableProduct("d.graph", :d_graph, "grass78/bin"),
    # ExecutableProduct("d.legend", :d_legend, "grass78/bin"),
    # ExecutableProduct("d.rast", :d_rast, "grass78/bin"),
    # ExecutableProduct("d.colortable", :d_colortable, "grass78/bin"),

    # ExecutableProduct("ps.map", :ps_map, "grass78/bin"),

    # ExecutableProduct("test.r3flow", :test_r3flow, "grass78/bin"),
    # ExecutableProduct("test.raster3d.lib", :test_raster3d_lib, "grass78/bin"),

    # ExecutableProduct("echo", :echo, "grass78/etc"),
    # ExecutableProduct("run", :grass_run, "grass78/etc"),
    # ExecutableProduct("lock", :grass_lock, "grass78/etc"),
    # ExecutableProduct("current_time_s_ms", :current_time_s_ms, "grass78/etc"),
    # ExecutableProduct("clean_temp", :clean_temp, "grass78/etc"),

    # ExecutableProduct("m.cogo", :m_cogo, "grass78/bin"),
    # ExecutableProduct("m.transform", :m_transform, "grass78/bin"),
    # ExecutableProduct("m.measure", :m_measure, "grass78/bin"),
    # ExecutableProduct("m.nviz.script", :m_nviz_script, "grass78/bin"),

    # ExecutableProduct("t.connect", :t_connect, "grass78/bin"),

    # ExecutableProduct("dbf", :dbf, "grass78/driver/db"),
    # ExecutableProduct("sqlite", :sqlite, "grass78/driver/db"),
    # ExecutableProduct("ogr", :ogr, "grass78/driver/db"),
    # ExecutableProduct("seg", :seg, "grass78/etc/r.watershed"),
    # ExecutableProduct("ram", :ram, "grass78/etc/r.watershed"),
    # ExecutableProduct("vector", :vector, "grass78/etc/lister"),
    # ExecutableProduct("cell", :cell, "grass78/etc/lister")

]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"))
    Dependency(PackageSpec(name="PROJ_jll", uuid="58948b4f-47e0-5654-a9ad-f609743f8632"))
    Dependency(PackageSpec(name="Cairo_jll", uuid="83423d85-b0ee-5818-9007-b63ccbeb887a"))
    Dependency(PackageSpec(name="FreeType2_jll", uuid="d7e528f0-a631-5988-bf34-fe36492bcfd7"); compat="2.10.4")
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0", julia_compat="1.6")
