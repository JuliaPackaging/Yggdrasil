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
function offset_version(upstream, offset)
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

    platforms = supported_platforms(; experimental=true)
    filter!(p -> nbits(p) == 64, platforms) # we only care about 64bit builds
    filter!(!Sys.iswindows, platforms)      # Windows is not supported

    dependencies = BinaryBuilder.AbstractDependency[
        Dependency("GAP_jll", gap_version; compat="~$(gap_version)"),
        Dependency("GAP_lib_jll", gap_lib_version; compat="~$(gap_lib_version)"),
    ]


    # HACK HACK HACK: the gac and sysinfo.gap shipped in GAP_jll are currently broken.
    # We modify sources and script below to work around that. This should eventually go,
    # once GAP_jll is fixed

    global sources
    sources = [
        DirectorySource("../bundled"),
        sources...
    ]

    global script
    script = raw"""
    # HACK WORKAROUND GAP_jll deficiencies
    # TODO: tweak for mac build
    if [[ "${target}" == *darwin* ]]; then
      cp gac-darwin ${prefix}/share/gap/gac
    else
      cp gac ${prefix}/share/gap/gac
    fi
    chmod a+x ${prefix}/share/gap/gac
    cp sysinfo.gap ${prefix}/share/gap/
    """ * script * raw"""
    rm -rf ${prefix}/include
    rm -rf ${prefix}/share/gap
    """

    return platforms, dependencies
end
