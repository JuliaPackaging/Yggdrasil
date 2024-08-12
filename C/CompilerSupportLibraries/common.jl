using BinaryBuilder, SHA
using BinaryBuilderBase: aatriplet

include("../../fancy_toys.jl")

function build_csl(ARGS, version::VersionNumber;
                   # Note: use preferred_gcc_version=v"100" to always force
                   # latest compatible version.
                   preferred_gcc_version::VersionNumber,
                   windows_staticlibs::Bool,
                   julia_compat::String,
                   )
    name = "CompilerSupportLibraries"

    # We are going to need to extract the latest libstdc++ and libgomp from BB
    # So let's grab them into tarballs by using preferred_gcc_version:
    extraction_script = raw"""
mkdir -p ${libdir}
for d in /opt/${target}/${target}/lib*; do
    # Copy all the libstdc++ and libgomp files:
    cp -av ${d}/libstdc++*.${dlext}* ${libdir} || true
    cp -av ${d}/libgomp*.${dlext}* ${libdir} || true
    # `libgcc_s` changed ABI for darwin platforms in GCC 12, so we have `libgcc_s.1.dylib`
    # until GCC 11, and `libgcc_s.1.1.dylib` after that.  Since `libstdc++` links to
    # `libgcc_s` we need to make sure it's able to find its depedency, also in the
    # libgfortran{3,4} packages.
    if [[ ${target} == x86_64-apple-darwin* ]]; then
        cp -av ${d}/libgcc_s.*.${dlext}* ${libdir} || true
    fi
    # Don't copy `.a` or `.py` files.  >:[
    rm -f ${libdir}/*.a ${libdir}/*.py
done
"""

    extraction_platforms = supported_platforms(;experimental=true)
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
                               # Force latest compatible version.
                               preferred_gcc_version,
                               verbose="--verbose" in ARGS,
                               debug="--debug" in ARGS,
                               )
    end

    ## Now that we've got those tarballs, we're going to use them as sources to overwrite
    ## the libstdc++ and libgomp that we would otherwise get from our compiler shards:
    script = "WINDOWS_STATICLIBS=$(windows_staticlibs)\nPREFERRED_GCC_VERSION=$(preferred_gcc_version)\nVERSION=$(version.major * 100 ^ 2 + version.minor * 100 + version.patch)\n" * raw"""
# Start by extracting LatestLibraries
tar -zxvf ${WORKSPACE}/srcdir/LatestLibraries*.tar.gz -C ${prefix}

# Make sure expansions aren't empty
shopt -s nullglob

# copy out all the libraries we can find except libstdc++ and libgomp,
# which we copied out in the extraction step above.
for lib in /opt/${target}/${target}/lib*/*.${dlext}*; do
    if [[ "${lib}" != *libstdc++* ]] && [[ "${lib}" != *libgomp* ]]; then
        cp -uav "${lib}" "${libdir}/"
    fi
done

# libwinpthread is a special snowflake and is only within `bin` for some reason
if [[ ${target} == *mingw* ]]; then
    cp -uav /opt/${target}/${target}/sys-root/bin/*.${dlext}* ${libdir}/
    if [[ "${WINDOWS_STATICLIBS}" == "true" ]]; then
        # From v1.1.0 of CSL we move the Windows `*.a` files to a subdir of `${prefix}/lib`.
        # See <https://github.com/JuliaLang/julia/issues/48081>.
        if [[ "${VERSION}" -ge 10100 ]]; then
           destdir="${prefix}/lib/gcc/${target}/${PREFERRED_GCC_VERSION%.*.*}"
        else
           destdir="${prefix}/lib"
        fi
        # Install also some static and import libraries, needed for linking of pkgimages.
        for lib in libmsvcrt.a libgcc.a libgcc_s.a libssp.dll.a; do
            qfind "/opt/${target}" -name "${lib}" -exec install -Dvm 0644 '{}' "${destdir}/${lib}" \;
        done
    fi
fi

# Delete .a and .py files, we don't want those.
rm -f ${libdir}/*.a ${libdir}/*.py

# Delete any `.so` files that are not ELF files, since they're mostly likely linker scripts
for f in ${libdir}/*.so; do
    if [[ "$(file -b "$(realpath "$f")")" != ELF* ]]; then
        rm -vf "$f"
    fi
done

# change permissions so that rpath succeeds
for l in ${libdir}/*; do
    chmod 0755 "${l}"
done

# libgcc_s.X.dylib receives special treatment for now.  We need to reset the dylib id,
# but we don't want to run a full audit, so we do it ourselves.
if [[ ${target} == *apple* ]]; then
    for libgcc_s in ${libdir}/libgcc_s.*.dylib; do
        LIBGCC_NAME=$(basename "${libgcc_s}")
        install_name_tool -id @rpath/${LIBGCC_NAME} "${libdir}/${LIBGCC_NAME}"
        if [[ "${LIBGCC_NAME}" == "libgcc_s.1.dylib" ]] && [[ "${PREFERRED_GCC_VERSION%.*.*}" -ge 12 ]]; then
            # GCC 12 on x86_64-apple-darwin changed the ABI of libgcc_s from 1 to 1.1, but keeping a compatibility shim
            # called libgcc_s.1.dylib which forwards all calls to libgcc_s.1.1.dylib.  We have to manually fix the path
            # of the dependency because the auditor won't do it: <https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1243>.
            install_name_tool -change "/workspace/destdir/${target}/lib/libgcc_s.1.1.dylib" "@rpath/libgcc_s.1.1.dylib" "${libdir}/${LIBGCC_NAME}"
        fi
    done
fi

# Remove extraneous libraries
rm -f ${libdir}/{libiconv,libxml2,libz}*.${dlext}*

# Install license (we license these all as GPL3, since they're from GCC)
install_license /usr/share/licenses/GPL-3.0+
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
            if windows_staticlibs && Sys.iswindows(platform)
                destdir = version >= v"1.1.0" ? "lib/gcc/$(aatriplet(platform))/$(preferred_gcc_version.major)" : "lib"
                products = vcat(products,
                                [FileProduct("$(destdir)/libmsvcrt.a", :libmsvcrt_a),
                                 FileProduct("$(destdir)/libgcc.a", :libgcc_a),
                                 FileProduct("$(destdir)/libgcc_s.a", :libgcc_s_a),
                                 FileProduct("$(destdir)/libssp.dll.a", :libssp_dll_a),
                                 ])
            end
            if libc(platform) != "musl"
                products = vcat(products, LibraryProduct("libssp", :libssp))
            end
            build_tarballs(ARGS, name, version, sources, script, [platform], products, []; preferred_gcc_version, julia_compat)
        end
    end
end
