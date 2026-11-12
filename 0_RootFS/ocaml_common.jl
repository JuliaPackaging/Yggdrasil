name = "OCaml"
version = v"5.3"

compiler_target = try
    parse(Platform, ARGS[end])
catch
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))

# These are the targets we support right now:
#   x86_64-linux-musl
#   x86_64-linux-gnu
#   x86_64-w64-mingw32
#   x86_64-apple-darwin14
#   aarch64-apple-darwin20
#   aarch64-linux-gnu
#   aarch64-linux-musl
#   riscv64-linux-gnu
#   riscv64-linux-musl
#   powerpc64le-linux-gnu
#
# Always build x86_64-linux-musl first, since the other targets depend on it.
#
# Not supported:
#  i686: OCaml 5.0 dropped support for 32-bit platforms
#  freebsd: `POSIX threads are required but not supported on this platform`

script = "host=$(BinaryBuilder.aatriplet(host_platform))\n" *raw"""
cd ${WORKSPACE}/srcdir/ocaml
git submodule update --init

# Apply patches
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# OCaml is not relocatable, so configure it with the prefix where the shards will end up.
# This should improve in the future: https://github.com/ocaml/RFCs/pull/53
# Alternatively, consider using the https://github.com/dra27/ocaml repository.
runtime_prefix=$(echo /opt/${target}*)
rsync --archive $runtime_prefix/ ${WORKSPACE}/initial_prefix/

# unset compiler env vars so that configure can detect them properly
unset CC CXX LD STRIP AS


## host compiler & tools

if [[ "${host}" == "${target}" ]]; then
    ./configure --prefix=${runtime_prefix}
    make -j${nproc}
    make install

    # Dune
    cd ${WORKSPACE}/srcdir/dune
    ./configure --prefix $runtime_prefix
    make release
    make install

    # OCamlbuild
    # XXX: OCamlbuild takes its configuration values from ocamlc, so picks up host settings...
    cd ${WORKSPACE}/srcdir/ocamlbuild
    make configure OCAMLBUILD_PREFIX=$runtime_prefix OCAMLBUILD_BINDIR=$runtime_prefix/bin OCAMLBUILD_LIBDIR=$runtime_prefix/lib/ocaml
    make -j${nproc}
    make install PREFIX=$runtime_prefix BINDIR=$runtime_prefix/bin LIBDIR=$runtime_prefix/lib/ocaml

    # ocamlfind
    cd ${WORKSPACE}/srcdir/ocamlfind
    ./configure -bindir $runtime_prefix/bin -mandir $runtime_prefix/man -sitelib $runtime_prefix/lib/ocaml -config $runtime_prefix/etc/findlib.conf -no-topfind
    make -j ${nproc}
    make install prefix=""
else
    # Build a temporary host compiler for bootstrapping the cross-compiler.
    # We could re-use the host shard, but that complicates the rootfs selection logic.
    ./configure --prefix=${host_prefix} --build=${host} --host=${host}
    make -j${nproc}
    make install

    # Make sure the host prefix takes precedence over the runtime prefix.
    # This matters when, during installation of the cross-compiler,
    # its `ocamlrun` would otherwise (fail to) execute instead.
    export PATH=${host_prefix}/bin:$PATH
fi


## cross compiler

if [[ "${host}" != "${target}" ]]; then
    cd ${WORKSPACE}/srcdir/ocaml
    make distclean

    # Build a cross-compiler
    ./configure --prefix=${runtime_prefix} --build=${host} --host=${host} --target=${target}
    make crossopt -j${nproc}
    make installcross

    # Fix shebang of ocamlrun scripts to not hardcode a path of the build environment
    for bin in $(file ${runtime_prefix}/bin/* | grep "a \S*/ocamlrun script" | cut -d: -f1); do
        abspath=$(file ${bin} | grep -oh "a \S*/ocamlrun script" | cut -d' ' -f2)
        sed -i "s?${abspath}?/usr/bin/env ocamlrun?" "${bin}"
    done

    # Fix extensions of native binaries
    if [[ "${target}" == *-mingw* ]]; then
        for bin in ${runtime_prefix}/bin/*.exe; do
            # (links to) target binaries should retain their extension
            if file -L $bin | grep 'PE32' >/dev/null; then
                continue
            fi

            # if this is a symlink, update both the name of the link and the target
            if [[ -L $bin ]]; then
                path=$(readlink $bin)
                rm $bin
                ln -s $(basename ${path} .exe) ${runtime_prefix}/bin/$(basename ${bin} .exe)

            # if this is a file, simply rename it
            elif [[ -f $bin ]]; then
                mv $bin ${runtime_prefix}/bin/$(basename ${bin} .exe)
            fi
        done
    fi
fi


## finalize

# Move the installed files to the expected location
rsync --archive --compare-dest=$WORKSPACE/initial_prefix/ $runtime_prefix/ $prefix/
find $prefix/ -type d -empty -delete
rsync --archive --delete ${WORKSPACE}/initial_prefix/ $runtime_prefix/
rm -rf ${WORKSPACE}/initial_prefix
"""

platforms = Platform[ host_platform ]
products = Product[
    # build with no products since all of our products are for the host, not the target

    # ExecutableProduct("ocamlopt.opt", :ocamlopt),
    # ExecutableProduct("ocamlc.opt", :ocamlc),
    # ExecutableProduct("ocamlrun", :ocamlrun),
]
dependencies = Dependency[]

# Build the tarballs. This needs to run in the target's environment, as the OCaml build
# system needs a target compiler to assemble the runtime libraries.
ndARGS, deploy_target = find_deploy_arg(ARGS)
build_info = build_tarballs(ndARGS, name, version, sources, script, [compiler_target], products, dependencies;
                            skip_audit=true, julia_compat="1.6", preferred_gcc_version=v"6")

build_info = Dict(host_platform => first(values(build_info)))

# Upload the artifacts (if requested)
if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info; target=compiler_target)
end
