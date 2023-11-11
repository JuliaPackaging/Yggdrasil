using BinaryBuilder, Pkg

name = "bowtie"

function build_bowtie(
    version::VersionNumber,
    sources::Vector{GitSource},
    script::String,
    platforms::Vector{Platform},
    products::Vector{ExecutableProduct},
    dependencies,
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
        preferred_gcc_version = v"5",
    )
end
