using BinaryBuilder, Pkg

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

# GCC version for building the whole system
gcc_version = v"6"

# Versions of various COIN-OR libraries
Cbc_version = v"2.10.5"
Cbc_gitsha = "7b5ccc016f035f56614c8018b20d700978144e9f"

Cgl_upstream_version = v"0.60.2"
Cgl_gitsha = "6377b88754fafacf24baac28bb27c0623cc14457"
Cgl_version_offset = v"0.0.0"
Cgl_version = offset_version(Cgl_upstream_version, Cgl_version_offset)

Clp_upstream_version = v"1.17.6"
Clp_gitsha = "756ddd3ed813eb1fa8b2d1b4fe813e6a4d7aa1eb"
Clp_version_offset = v"0.0.0"
Clp_version = offset_version(Clp_upstream_version, Clp_version_offset)

Osi_version = v"0.108.5"
Osi_gitsha = "2bd34ae6b8c93d342d54fd19d4d773f07194583c"

CoinUtils_version = v"2.11.3"
CoinUtils_gitsha = "ea66474879246f299e977802c94a0e45334e7afb"

# Third-party packages needed by COIN-OR libraries.
METIS_version = v"5.1.0"
MUMPS_seq_version = v"5.2.1"
OpenBLAS32_version = v"0.3.9"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = filter!(!Sys.isfreebsd, platforms)
