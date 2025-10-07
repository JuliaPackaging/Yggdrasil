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
Bonmin_version_offset = v"0.0.2"
Bonmin_version = offset_version(Bonmin_upstream_version, Bonmin_version_offset)

Couenne_version = offset_version(v"0.5.8", v"0.0.2")
Couenne_gitsha = "7154f7a9b3cd84be378d02b483d090b76fc79ce8"

Cbc_version = offset_version(v"2.10.12", v"0.0.0")
Cbc_gitsha = "782d275a8efa569eb818551561b424948e19653c"

Cgl_version = offset_version(v"0.60.9", v"0.0.0")
Cgl_gitsha = "1d91b9ccb57eafbb7c07e994089a0f124358ffbd"

Clp_version = offset_version(v"1.17.10", v"0.0.0")
Clp_gitsha = "9a3efaa9ecefeb2a6088a447c9f66c6f31edbed9"

Osi_version = offset_version(v"0.108.11", v"0.0.0")
Osi_gitsha = "d979b7b890a32a7e69c53920bb39eef17bd599b8"

CoinUtils_version = offset_version(v"2.11.12", v"0.0.0")
CoinUtils_gitsha = "cc644574ef1899f14b7318e6cdb7f460bbee5212"

Ipopt_upstream_version = v"3.14.19"
Ipopt_gitsha = "2695946fa79d2e84f3034e065e788933a81466eb"
Ipopt_verson_offset = v"0.0.0"
Ipopt_version = offset_version(Ipopt_upstream_version, Ipopt_verson_offset)

ALPS_version = offset_version(v"1.5.12", v"0.0.0")
ALPS_gitsha = "c90858e4ca11c7f81168cd14dc137742fa3510f0"

BiCePS_version = offset_version(v"0.94.9", v"0.0.0")
BiCePS_gitsha = "0b60a72f7b52b2bae813dedd0e08aab5579e0218"

CHiPPS_BLIS_version = offset_version(v"0.94.13", v"0.0.0")
CHiPPS_BLIS_gitsha = "0262763cdd8f77f1ea6ec506c4b5ccae19b4451c"

SYMPHONY_version = offset_version(v"5.7.3", v"0.0.0")
SYMPHONY_gitsha = "03006fc6dcf77da9becc7e55e8a0879201905b96"

MibS_version = offset_version(v"1.2.2", v"0.0.0")
MibS_gitsha = "956d5dbfa0482c5d10b7ee40fea58cbae484dd46"

SHOT_gitsha = "11fda1ecb84af9718f1e0c0ebf7ae5ae8c45041a"
SHOT_version = offset_version(v"1.1.0", v"0.0.0")

# Third-party packages needed by COIN-OR libraries.
Julia_compat_version = "1.6"
ASL_version = v"0.1.3"
METIS_version = v"5.1.2"
MUMPS_seq_version = v"5.4.1"
MUMPS_seq_version_LBT = v"500.800.100"
SPRAL_version_LBT = v"2025.5.20"
OpenBLAS32_version = v"0.3.26"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = filter!(!Sys.isfreebsd, platforms)
filter!(p -> arch(p) != "riscv64", platforms)
