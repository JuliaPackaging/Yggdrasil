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

Bonmin_upstream_version = v"1.8.8"
Bonmin_gitsha = "65c56cea1e7c40acd9897a2667c11f91d845bb7b"
Bonmin_version_offset = v"0.0.1"
Bonmin_version = offset_version(Bonmin_upstream_version, Bonmin_version_offset)

Couenne_version = offset_version(v"0.5.8", v"0.0.1")
Couenne_gitsha = "7154f7a9b3cd84be378d02b483d090b76fc79ce8"

Cbc_upstream_version = v"2.10.5"
Cbc_gitsha = "7b5ccc016f035f56614c8018b20d700978144e9f"
Cbc_version_offset = v"0.0.1"
Cbc_version = offset_version(Cbc_upstream_version, Cbc_version_offset)

Cgl_upstream_version = v"0.60.3"
Cgl_gitsha = "31797b2997219934db02a40d501c4b6d8efa7398"
Cgl_version_offset = v"0.0.0"
Cgl_version = offset_version(Cgl_upstream_version, Cgl_version_offset)

Clp_upstream_version = v"1.17.6"
Clp_gitsha = "756ddd3ed813eb1fa8b2d1b4fe813e6a4d7aa1eb"
Clp_version_offset = v"0.0.1"
Clp_version = offset_version(Clp_upstream_version, Clp_version_offset)

Osi_upstream_version = v"0.108.6"
Osi_gitsha = "dfa6449d6756fdd96912cf96e168d0be07b1d37c"
Osi_version_offset = v"0.0.0"
Osi_version = offset_version(Osi_upstream_version, Osi_version_offset)

CoinUtils_upstream_version = v"2.11.4"
CoinUtils_gitsha = "f709081c9b57cc2dd32579d804b30689ca789982"
CoinUtils_verson_offset = v"0.0.0"
CoinUtils_version =
    offset_version(CoinUtils_upstream_version, CoinUtils_verson_offset)

Ipopt_upstream_version = v"3.14.4"
Ipopt_gitsha = "d872b3a3d17863c6a2a27475cc9af9e933cb7e92"
Ipopt_verson_offset = v"0.0.1"
Ipopt_version = offset_version(Ipopt_upstream_version, Ipopt_verson_offset)

ALPS_upstream_version = v"1.5.7"
# This is not the exact 1.5.7 tag, but a few commits later on stable/1.5
ALPS_gitsha = "5b1a0b524979764d6ca929446762762712c035bb"
ALPS_version_offset = v"0.0.2"
ALPS_version = offset_version(ALPS_upstream_version, ALPS_version_offset)

BiCePS_version = offset_version(v"0.94.4", v"0.0.0")
BiCePS_gitsha = "8e41545a3b1a36ca1d306b3af96f3804dc57e61f"

CHiPPS_BLIS_version = offset_version(v"0.94.8", v"0.0.2")
# This is not the exact 0.94.8 tag, but a few commits later on releases/0.94.8
CHiPPS_BLIS_gitsha = "0ad6d4530d48e3b5f417a3407f5f2e8605145b50"

SYMPHONY_upstream_version = v"5.6.17"
SYMPHONY_gitsha = "f917d42e6655a82ea4e9290aa7d41b0f60a91f20"
SYMPHONY_version_offset = v"0.0.0"
SYMPHONY_version =
    offset_version(SYMPHONY_upstream_version, SYMPHONY_version_offset)

MibS_version = offset_version(v"1.1.3", v"0.0.1")
MibS_gitsha = "4b7ec93c4bd1d6a978deff9987cf1df74f6598d3"

SHOT_gitsha = "11fda1ecb84af9718f1e0c0ebf7ae5ae8c45041a"
SHOT_version = offset_version(v"1.1.0", v"0.0.0")

# Third-party packages needed by COIN-OR libraries.
ASL_version = v"0.1.3"
METIS_version = v"5.1.1"
MUMPS_seq_version = v"5.5.1"
OpenBLAS32_version = v"0.3.10"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = filter!(!Sys.isfreebsd, platforms)
