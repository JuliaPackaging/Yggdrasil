# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

"""
    offset_version(upstream, offset)

Compute a version that allows distinguishing between changes in the upstream
version and changes to the JLL which retain the same upstream version.

When the `upstream` version is changed, `offset` version numbers should be reset
to `v"0.0.0"` and incremented following semantic versioning.
"""
function offset_version(upstream_str, offset)
    upstream = VersionNumber(replace(upstream_str, "-" => "."))
    return VersionNumber(
        upstream.major * 100 + offset.major,
        upstream.minor * 100 + offset.minor,
        upstream.patch * 100 + offset.patch,
    )
end

function gap_pkg_name(name::String)
    # turn the name into a canonical form; in particular, since GAP
    # treats package names case insensitive, but Julia does not, turn
    # them all into lowercase to protect against accidental changes.
    # This allows us elsewhere to generate Julia  and GAP code
    # referencing these JLLs in a uniform way.
    return "GAP_pkg_$(lowercase(name))"
end

function setup_gap_package(gap_version::VersionNumber, gap_lib_version::VersionNumber = gap_version)

    platforms = supported_platforms()
    filter!(p -> nbits(p) == 64, platforms) # we only care about 64bit builds
    filter!(!Sys.iswindows, platforms)      # Windows is not supported

    # TODO: re-enable FreeBSD aarch64 support once GAP_jll supports it (which in
    # turn require libjulia_jll)
    filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

    dependencies = BinaryBuilder.AbstractDependency[
        Dependency("GAP_jll", gap_version; compat="~$(gap_version)"),
        Dependency("GAP_lib_jll", gap_lib_version; compat="~$(gap_lib_version)"),
    ]

    return platforms, dependencies
end
