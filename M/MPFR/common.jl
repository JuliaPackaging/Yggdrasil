using BinaryBuilder
using BinaryBuilderBase: sanitize
using Pkg

# Version overview:
# - 4.1.1: Bundled with Julia 1.6, 1.7, 1.8, 1.9
# - 4.2.0: Bundled with Julia 1.10
# - 4.2.1: Bundled with Julia 1.11
# - 4.2.2: Bundled with Julia 1.12-beta4

# Collection of sources required to build MPFR
function mpfr_sources(version::VersionNumber; kwargs...)
    mpfr_version_sources = Dict(
        v"4.1.1" => [
            ArchiveSource("https://www.mpfr.org/mpfr-$(version)/mpfr-$(version).tar.xz",
                          "ffd195bd567dbaffc3b98b23fd00aad0537680c9896171e44fe3ff79e28ac33d"),
        ],
        v"4.2.0" => [
            ArchiveSource("https://www.mpfr.org/mpfr-$(version)/mpfr-$(version).tar.xz",
                          "06a378df13501248c1b2db5aa977a2c8126ae849a9d9b7be2546fb4a9c26d993"),
        ],
        v"4.2.1" => [
            ArchiveSource("https://www.mpfr.org/mpfr-$(version)/mpfr-$(version).tar.xz",
                          "277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2"),
        ],
        v"4.2.2" => [
            ArchiveSource("https://www.mpfr.org/mpfr-$(version)/mpfr-$(version).tar.xz",
                          "b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01"),
        ],
    )
    return [
        mpfr_version_sources[version]...,
    ]
end

# Bash recipe for building across all platforms
function mpfr_script(; kwargs...)
    script = raw"""
    if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
        # Install msan runtime (for clang)
        cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
    fi

    cd $WORKSPACE/srcdir/mpfr-*
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared --disable-static --with-gmp=${prefix} --enable-thread-safe --enable-shared-cache --disable-float128 --disable-decimal-float
    make -j${nproc}
    make install

    # On Windows, make sure non-versioned filename exists...
    if [[ ${target} == *mingw* ]]; then
        cp -v ${libdir}/libmpfr-*.dll ${libdir}/libmpfr.dll
    fi
    """
    return script
end

function mpfr_platforms(; kwargs...)
    platforms = supported_platforms()
    push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))
    return platforms
end

# The products that we will ensure are always built
function mpfr_products(; kwargs...)
    return [
        LibraryProduct("libmpfr", :libmpfr),
    ]
end

function mpfr_dependencies(platforms; llvm_compilerrt_version=v"13.0.1", kwargs...)
    return [
        Dependency("GMP_jll", v"6.2.1"),
        BuildDependency(PackageSpec(name="LLVMCompilerRT_jll",
                                uuid="4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version=llvm_compilerrt_version);
                                platforms=filter(p -> sanitize(p)=="memory", platforms)),
    ]
end
