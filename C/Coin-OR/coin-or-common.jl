using BinaryBuilder, Pkg

# GCC version for building the whole system
gcc_version = v"6"

# Versions of various Coin-OR libraries
Cbc_version = v"2.10.3"
Cbc_gitsha = "6fe3addaa76436d479d4431add67b371e11d3e83"

Cgl_version = v"0.60.2"
Cgl_gitsha = "6377b88754fafacf24baac28bb27c0623cc14457"
Cgl_packagespec = PackageSpec(; name = "Cgl_jll",
                              uuid = "3830e938-1dd0-5f3e-8b8e-b3ee43226782",
                              version = Cgl_version)

Clp_version = v"1.16.11"
Clp_gitsha = "aae123d7a3c633a382b7cb9c1f4f78ed6559a10b"
Clp_packagespec = PackageSpec(; name = "Clp_jll",
                              uuid = "06985876-5285-5a41-9fcb-8948a742cc53",
                              version = Clp_version)

Osi_version = v"0.108.5"
Osi_gitsha = "2bd34ae6b8c93d342d54fd19d4d773f07194583c"
Osi_packagespec = PackageSpec(; name = "Osi_jll",
                              uuid = "7da25872-d9ce-5375-a4d3-7a845f58efdd",
                              version = Osi_version)

CoinUtils_version = v"2.11.3"
CoinUtils_gitsha = "ea66474879246f299e977802c94a0e45334e7afb"
CoinUtils_packagespec = PackageSpec(; name = "CoinUtils_jll",
                                    uuid = "be027038-0da8-5614-b30d-e42594cb92df",
                                    version = CoinUtils_version)

MUMPS_seq_version = v"4.10.0"
MUMPS_seq_packagespec = PackageSpec(; name = "MUMPS_seq_jll",
                                uuid = "d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d",
                                version = MUMPS_seq_version)

METIS_version = v"4.0.3"
METIS_packagespec = PackageSpec(; name = "METIS_jll",
                                uuid = "d00139f3-1899-568f-a2f0-47f597d42d70",
                                version = METIS_version)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]
