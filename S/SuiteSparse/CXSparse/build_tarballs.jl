using BinaryBuilder, Pkg, LibGit2
using BinaryBuilderBase: get_addable_spec

const cxsparsescript = raw"""
# First, find (true) SuiteSparse library directory in ~/.artifacts somewhere
SS_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/include/cs.h)))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `libMLIR` and `include`, specifically.
mkdir -p ${prefix}/include ${libdir} ${prefix}/lib
mv -v ${SS_ARTIFACT_DIR}/include/cs.h ${prefix}/include/

mv -v ${SS_ARTIFACT_DIR}/$(basename ${libdir})/*cxsparse*.${dlext}* ${libdir}/
install_license ${SS_ARTIFACT_DIR}/share/licenses/SuiteSparse*/*
"""

function configure_extraction(ARGS, name, SuiteSparse_version=nothing; experimental_platforms=false)
    if isempty(SuiteSparse_version.build)
        error("You must lock an extracted LLVM build to a particular LLVM_full build number!")
    end

    version = VersionNumber(SuiteSparse_version.major, SuiteSparse_version.minor, SuiteSparse_version.patch)
    compat_version = "$(version.major).$(version.minor).$(version.patch)"
    if name == "CXSparse"
        script = cxsparsescript
        products = Product[
	    LibraryProduct(["libcxsparse"], :libcxsparse)
        ]
    end
    platforms = expand_cxxstring_abis(supported_platforms(;experimental=experimental_platforms))

    dependencies = BinaryBuilder.AbstractDependency[
    ]

    ctx = Pkg.Types.Context()
    name = "SuiteSparse_jll"
    first(Pkg.Types.registry_resolve!(ctx.registries, Pkg.Types.PackageSpec(;name))).uuid
UUID("bea87d4a-7f5b-5778-9afe-8cc45184846c")
    push!(dependencies, BuildDependency(get_addable_spec("SuiteSparse_jll", SuiteSparse_version;ctx)))

    return name, version, [], script, platforms, products, dependencies
end

name = "CXSparse"
SuiteSparse_version = v"5.10.1+2"

build_tarballs(ARGS, configure_extraction(ARGS, name, SuiteSparse_version; experimental_platforms=true)...; skip_audit=true,  julia_compat="1.7")
