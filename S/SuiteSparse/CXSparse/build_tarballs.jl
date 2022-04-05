using BinaryBuilder, Pkg, LibGit2
using BinaryBuilderBase: get_addable_spec

const cxsparsescript = raw"""
# First, find (true) SuiteSparse library directory in ~/.artifacts somewhere
SuiteSparse_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `libMLIR` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir} ${prefix}/lib
mv -v ${LLVM_ARTIFACT_DIR}/include/mlir* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/mlir* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*MLIR*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*mlir*.${dlext}* ${libdir}/
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
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
        ]
    end
    platforms = expand_cxxstring_abis(supported_platforms(;experimental=experimental_platforms))

    dependencies = BinaryBuilder.AbstractDependency[
    ]

    push!(dependencies, BuildDependency(get_addable_spec("SuiteSparse_jll", SuiteSparse_version)))

    return name, version, [], script, platforms, products, dependencies
end

name = "CXSparse"
SuiteSparse_version = v"5.10.1+2"

build_tarballs(ARGS, configure_extraction(ARGS, name, SuiteSparse_version; experimental_platforms=true)...; skip_audit=true,  julia_compat="1.7")
