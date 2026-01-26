using BinaryBuilder
using Pkg
using BinaryBuilderBase: sanitize

const llvm_version = v"13.0.1"

function configure_zlib_build(upstream_version::VersionNumber;
                              version::VersionNumber=upstream_version,
                              kwargs...)

    versions_tags = Dict(
        v"1.2.12" => "21767c654d31d2dccdde4330529775c6c5fd5389",
        v"1.3.1" => "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf",
    )

    name = "Zlib"

    sources = [
        # use Git source because zlib has a track record of deleting release tarballs of old versions
        GitSource("https://github.com/madler/zlib.git", versions_tags[upstream_version]),
    ]

    script = raw"""
    cd $WORKSPACE/srcdir/zlib*
    mkdir build && cd build
    if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
        # Install msan runtime (for clang)
        cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
    fi
    # We use `-DUNIX=true` to ensure that it is always named `libz` instead of `libzlib` or something absolutely absurd like that.
    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DUNIX=true \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        ..
    make install -j${nproc}
    install_license ../README
    """

    platforms = supported_platforms()
    push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

    products = [
        LibraryProduct("libz", :libz),
    ]

    dependencies = [
        BuildDependency(PackageSpec(; name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version); platforms=filter(p -> sanitize(p)=="memory", platforms)),
    ]

    return name, version, sources, script, platforms, products, dependencies
end
