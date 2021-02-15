include("../common.jl")

# Offset to add to the version number
version_offset = v"0.1.0"
# Minimum Julia version supported: this is important to decide which versions of
# the dependencies to use, in particular the JLL stdlibs.
min_julia_version = v"1.3"
# Fix to minor PROJ version; also update PROJ_LIBS
# needed for Windows because of https://github.com/OSGeo/PROJ/blob/949171a6e/cmake/ProjVersion.cmake#L40-L46
# to avoid this problem https://github.com/JuliaGeo/GDAL.jl/pull/102
# Note that this currently fixes it to the exact JLL version that is used,
# this is issue https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/89.
# Ideally we could by default allow any version X??.Y?? here, i.e. the PROJ minor version.
proj_jll_version = "700.201"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, configure(version_offset, min_julia_version, proj_jll_version)...;
    julia_compat="~1.0, ~1.1, ~1.2, ~1.3, ~1.4, ~1.5",
    preferred_gcc_version=v"6")
