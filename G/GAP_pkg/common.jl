using BinaryBuilder

"""
    offset_version(upstream, offset)

Compute a version that allows distinguishing between changes in the upstream
version and changes to the JLL which retain the same upstream version.

To match the gap code of a package with its kernel extension jll, we need to
make sure that any change to the upstream version is reflected at least
as a minor version change. Patch versions are just for changes in jll
dependencies, updated gap version etc.

When the `upstream` version is changed, `offset` version numbers should be reset
to `v"0.0.0"` and incremented following semantic versioning.
"""
function offset_version(upstream_str, offset)
    upstream = VersionNumber(replace(upstream_str, "-" => "."))
    return VersionNumber(
        upstream.major * 100 + offset.major,
        upstream.minor * 10000 + upstream.patch * 100 + offset.minor,
        offset.patch,
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

include("../GAP/common.jl") # make gap_platforms available

function gap_pkg_dependencies(gap_version::VersionNumber)
    return BinaryBuilder.AbstractDependency[
        Dependency("GAP_jll", gap_version; compat="~$(gap_version)"),
    ]
end
