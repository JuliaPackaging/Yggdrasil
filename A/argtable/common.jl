using BinaryBuilder, BinaryBuilderBase, Pkg

name = "argtable"

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

function build_argtable(
    version::VersionNumber,
    sources::Vector{<:AbstractSource},
    script::String,
    platforms::Vector{Platform},
    products::Vector{LibraryProduct},
)
    build_tarballs(
        ARGS,
        name,
        version,
        sources,
        script,
        platforms,
        products,
        dependencies;
        julia_compat = "1.6",
        preferred_gcc_version = v"7",
    )
end
