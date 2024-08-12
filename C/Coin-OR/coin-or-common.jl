# The C/Coin-OR directory contains a number of inter-related packages. Their
# dependency graph has the following topological order. Because we use strict
# equality compat bounds (relaxing to SemVer has caused compatibility issues in
# the past), when updating a package, you should also update all subsequent
# packages in the order.
#
# The order is:
#
# [CoinUtils_jll]
# [Osi_jll]
# [Clp_jll]
# [Cgl_jll]
# [Cbc_jll]
# [Bonmin_jll]
# [Couenne_jll]
# [SHOT_jll]
# [SYMPHONY_jll]
# [ALPS_jll]
# [BiCePS_jll]
# [CHIPPS_BLIS_jll]
# [MibS_jll]
#
# The other packages in C/Coin-OR that do not have dependencies are:
#
# [Ipopt_jll]
# [IpoptMKL_jll]
# [CDSP_jll]

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
gcc_version = v"8.1.0"

# LLVM version for building the whole system
llvm_version = v"13.0.1"

# Versions of various COIN-OR libraries

Bonmin_upstream_version = v"1.8.9"
Bonmin_gitsha = "030d111af16a0f30b6fff851ba7f983bea14f982"
Bonmin_version_offset = v"0.0.1"
Bonmin_version = offset_version(Bonmin_upstream_version, Bonmin_version_offset)

Couenne_version = offset_version(v"0.5.8", v"0.0.1")
Couenne_gitsha = "7154f7a9b3cd84be378d02b483d090b76fc79ce8"

Cbc_version = offset_version(v"2.10.8", v"0.0.0")
Cbc_gitsha = "3c1d759619f38bbd5916380df292cfc1dafba7f5"

Cgl_version = offset_version(v"0.60.6", v"0.0.0")
Cgl_gitsha = "8952b9e737e434b730fab5967cd28180b43d7234"

Clp_version = offset_version(v"1.17.9", v"0.0.1")
Clp_gitsha = "7b9daa62d4c2710a368a17385913ce59d8c67b68"

Osi_version = offset_version(v"0.108.10", v"0.0.0")
Osi_gitsha = "2997cda8e85ccc6712c4b05404e7aa70500e422f"

CoinUtils_upstream_version = v"2.11.11"
CoinUtils_version = offset_version(CoinUtils_upstream_version, v"0.0.0")
CoinUtils_gitsha = "15a819b7e8763b2557e4bf440f8cb62ee6734f36"
CoinUtils_hash = "27da344479f38c82112d738501643dcb229e4ee96a5f87d4f406456bdc1b2cb4"

Ipopt_upstream_version = v"3.14.16"
Ipopt_gitsha = "43a63412f73d9ad3ff9074d38b49362fc9d7f8f1"
Ipopt_verson_offset = v"0.0.0"
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

SYMPHONY_version = offset_version(v"5.6.19", v"0.0.0")
SYMPHONY_gitsha = "28adc89185be98780b1ab6528ab270e569561b87"

MibS_version = offset_version(v"1.1.3", v"0.0.1")
MibS_gitsha = "4b7ec93c4bd1d6a978deff9987cf1df74f6598d3"

SHOT_gitsha = "11fda1ecb84af9718f1e0c0ebf7ae5ae8c45041a"
SHOT_version = offset_version(v"1.1.0", v"0.0.0")

# Third-party packages needed by COIN-OR libraries.
Julia_compat_version = "1.6"
ASL_version = v"0.1.3"
METIS_version = v"5.1.2"
MUMPS_seq_version = v"5.4.1"
MUMPS_seq_version_LBT = v"500.700.300"
SPRAL_version_LBT = v"2024.5.8"
OpenBLAS32_version = v"0.3.26"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = filter!(!Sys.isfreebsd, platforms)
