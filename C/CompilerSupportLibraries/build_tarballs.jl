using BinaryBuilder, SHA

include("../../fancy_toys.jl")

name = "CompilerSupportLibraries"
version = v"0.3.4"

# We are going to need to extract the latest libstdc++ and libgomp from BB
# So let's grab them into tarballs by using preferred_gcc_version:
extraction_script = raw"""
mkdir -p ${libdir}
for d in /opt/${target}/${target}/lib*; do
    # Copy all the libstdc++ and libgomp files:
    cp -av ${d}/libstdc++*.${dlext}* ${libdir} || true
    cp -av ${d}/libgomp*.${dlext}* ${libdir} || true
    # Don't copy `.a` or `.py` files.  >:[
    rm -f ${libdir}/*.a ${libdir}/*.py
done
"""

extraction_platforms = supported_platforms()
extraction_products = [
    LibraryProduct("libstdc++", :libstdcxx),
    LibraryProduct("libgomp", :libgomp),
]

# Don't actually run extraction if we're asking for a JSON, but don't print it either
if any(startswith(a, "--meta-json") for a in ARGS)
    # How delightfully meta, for when we're calculating the meta!  ;D
    self_url = @__FILE__
    self_hash = open(io -> bytes2hex(sha256(io)), self_url)
    build_info = Dict(p => (self_url, self_hash) for p in BinaryBuilder.BinaryBuilderBase.abi_agnostic.(extraction_platforms))
else
    build_info = autobuild(joinpath(@__DIR__, "build", "extraction"),
        "LatestLibraries",
        version,
        FileSource[],
        extraction_script,
        # Only extract for platforms we're actually going to use
        filter(should_build_platform, extraction_platforms),
        extraction_products,
        Dependency[];
        skip_audit=true,
        preferred_gcc_version=v"100",
        verbose="--verbose" in ARGS,
        debug="--debug" in ARGS,
    )
end

## Now that we've got those tarballs, we're going to use them as sources to overwrite
## the libstdc++ and libgomp that we would otherwise get from our compiler shards:
script = raw"""
# Start by extracting LatestLibraries
tar -zxvf ${WORKSPACE}/srcdir/LatestLibraries*.tar.gz -C ${prefix}

echo ***********************************************************
echo LatestLibraries logs, reproduced here for debuggability:
zcat ${prefix}/logs/LatestLibraries.log.gz
echo ***********************************************************
rm -f ${prefix}/logs/LatestLibraries.log.gz

# Make sure expansions aren't empty
shopt -s nullglob

# copy out all the libraries we can find, not clobbering stuff from LL
for d in /opt/${target}/${target}/lib*; do
    cp -uav ${d}/*.${dlext}* ${libdir}/ || true
done

# libwinpthread is a special snowflake and is only within `bin` for some reason
if [[ ${target} == *mingw* ]]; then
    cp -uav /opt/${target}/${target}/sys-root/bin/*.${dlext}* ${libdir}/
fi

# Delete .a and .py files, we don't want those.
rm -f ${libdir}/*.a ${libdir}/*.py

# Delete any `.so` files that are not ELF files, since they're mostly likely linker scripts
for f in ${libdir}/*.so; do
    if [[ "$(file -b "$f")" != ELF* ]]; then
        rm -f "$f"
    fi
done

# change permissions so that rpath succeeds
for l in ${libdir}/*; do
    chmod 0755 "${l}"
done

# libgcc_s.1.dylib receives special treatment for now
if [[ ${target} == *apple* ]]; then
    install_name_tool -id @rpath/libgcc_s.1.dylib ${libdir}/libgcc_s.1.dylib
fi

# Install license (we license these all as GPL3, since they're from GCC)
install_license /usr/share/licenses/GPL3
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
common_products = [
    LibraryProduct(["libgcc_s", "libgcc_s_sjlj", "libgcc_s_seh"], :libgcc_s),
    LibraryProduct("libstdc++", :libstdcxx),
    LibraryProduct("libgfortran", :libgfortran),
    LibraryProduct("libgomp", :libgomp),
]

for platform in platforms
    if should_build_platform(platform)
        # Find the corresponding source for this platform
        tarball_path, tarball_hash = build_info[BinaryBuilder.BinaryBuilderBase.abi_agnostic(platform)][1:2]
        sources = [
            FileSource(tarball_path, tarball_hash),
        ]
        # Windows and aarch64 Linux don't have a libatomic on older GCC's
        products = if libgfortran_version(platform).major != 3 || !(Sys.iswindows(platform) || arch(platform) == "aarch64")
            # Don't push to the common products, otherwise we'll keep
            # accumulating libatomic into it when looping over all platforms.
            vcat(common_products, LibraryProduct("libatomic", :libatomic))
        else
            common_products
        end
        build_tarballs(ARGS, name, version, sources, script, [platform], products, [])
    end
end
