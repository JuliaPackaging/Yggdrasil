using BinaryBuilder, Pkg
using BinaryBuilderBase: sanitize

const llvm_version = v"13.0.1"

function configure_nghttp2_build(version; kwargs...)
    name = "nghttp2"

    versions_tags = Dict(
        v"1.41.0" => "8f7b008b158e12de0e58247afd170f127dbb6456",
        v"1.64.0" => "526ff38e0249acbcc4d0e8958c12cdeae9960cfe",
        v"1.65.0" => "319bf015de8fa38e21ac271ce2f7d61aa77d90cb",
        v"1.66.0" => "ac22e0efe3f82f43c1366961c89a50ee821cfba3",
        v"1.67.0" => "45ac57609bc21cef2463f46258d28a4dc0623333",
        v"1.67.1" => "49908f992027821912b96a13898b665a35aa3a0a",
        v"1.68.0" => "534b74b72524e962c18c7146470914632ca7eb2d",
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
