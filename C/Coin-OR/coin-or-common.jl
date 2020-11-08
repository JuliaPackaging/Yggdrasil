using BinaryBuilder, Pkg

# GCC version for building the whole system
gcc_version = v"6"

# Versions of various Coin-OR libraries
Cbc_version = v"2.10.5"
Cbc_gitsha = "7b5ccc016f035f56614c8018b20d700978144e9f"

Cgl_version = v"0.60.3"
Cgl_gitsha = "31797b2997219934db02a40d501c4b6d8efa7398"
Cgl_packagespec = PackageSpec(; name = "Cgl_jll",
                              uuid = "3830e938-1dd0-5f3e-8b8e-b3ee43226782",
                              version = Cgl_version)

Clp_version = v"1.17.6"
Clp_gitsha = "756ddd3ed813eb1fa8b2d1b4fe813e6a4d7aa1eb"
Clp_packagespec = PackageSpec(; name = "Clp_jll",
                              uuid = "06985876-5285-5a41-9fcb-8948a742cc53",
                              version = Clp_version)

Osi_version = v"0.108.6"
Osi_gitsha = "dfa6449d6756fdd96912cf96e168d0be07b1d37c"
Osi_packagespec = PackageSpec(; name = "Osi_jll",
                              uuid = "7da25872-d9ce-5375-a4d3-7a845f58efdd",
                              version = Osi_version)

CoinUtils_version = v"2.11.4"
CoinUtils_gitsha = "f709081c9b57cc2dd32579d804b30689ca789982"
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
