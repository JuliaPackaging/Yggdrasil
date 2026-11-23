# A version whose `build_tarballs.jl` starts with `using BinaryBuilder2` builds with
# BinaryBuilder2; the others build with BinaryBuilder.
if !@isdefined(BinaryBuilder2)
    using BinaryBuilder
    using Pkg
    using BinaryBuilderBase: sanitize
end

const llvm_version = v"13.0.1"

function configure_zlib_build(upstream_version::VersionNumber;
                              version::VersionNumber=upstream_version,
                              kwargs...)

    versions_tags = Dict(
        v"1.2.12" => "21767c654d31d2dccdde4330529775c6c5fd5389",
        v"1.3.1" => "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf",
        v"1.3.2" => "da607da739fa6047df13e66a2af6b8bec7c2a498",
        v"1.4.0" => "99623ef7097352da7993ba614161fd6a311e046e",
    )

    name = "Zlib"

    tag = if version.patch == 0
        # Omit patch number if it is zero
        "v$(version.major).$(version.minor)"
    else
        "v$(version)"
    end

    sources = [
        # use Git source because zlib has a track record of deleting release tarballs of old versions
        GitSource("https://github.com/madler/zlib.git", versions_tags[upstream_version]; tag),
    ]

    script = raw"""
    cd $WORKSPACE/srcdir/zlib*
    mkdir build && cd build
    # We use `-DUNIX=true` to ensure that it is always named `libz` instead of `libzlib` or something absolutely absurd like that.
    options=(
        -DCMAKE_INSTALL_PREFIX=${prefix}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
        -DCMAKE_BUILD_TYPE=Release
        -DUNIX=true
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DZLIB_BUILD_TESTING=OFF
        -DZLIB_BUILD_STATIC=OFF
    )
    cmake "${options[@]}" ..
    make install -j${nproc}
    install_license ../README
    """

    platforms = supported_platforms()
    push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

    products = [
        LibraryProduct("libz", :libz),
    ]

    if @isdefined(BinaryBuilder2)
        # BinaryBuilder2's clang comes with the msan runtime
        dependencies = []
    else
        # BinaryBuilder's clang lacks the msan runtime, so install it from LLVMCompilerRT_jll
        script = raw"""
        if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
            cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
        fi
        """ * script
        dependencies = [
            BuildDependency(PackageSpec(; name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=string(llvm_version));
                            platforms=filter(p -> sanitize(p)=="memory", platforms)),
        ]
    end

    return name, version, sources, script, platforms, products, dependencies
end
