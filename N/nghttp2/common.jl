using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

const llvm_version = v"13.0.1"

function configure_nghttp2_build(version; kwargs...)
    name = "nghttp2"

    versions_tags = Dict(
        v"1.41.0" => "8f7b008b158e12de0e58247afd170f127dbb6456",
        v"1.64.0" => "526ff38e0249acbcc4d0e8958c12cdeae9960cfe",
    )

    sources = [
        GitSource("https://github.com/nghttp2/nghttp2.git",
                  versions_tags[version]),
    ]

    script = raw"""
    cd $WORKSPACE/srcdir/nghttp2

    if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
        # Install msan runtime (for clang)
        cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
    fi

    autoreconf -i
    automake
    autoconf
    ./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --enable-lib-only
    make -j${nproc}
    make install
    """

    platforms = supported_platforms()
    push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

    products = [
        LibraryProduct("libnghttp2", :libnghttp2),
    ]

    dependencies = [
        BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version); platforms=filter(p -> sanitize(p)=="memory", platforms)),
    ]

    return name, version, sources, script, platforms, products, dependencies
end
