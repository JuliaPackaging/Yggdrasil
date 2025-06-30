# Check if deploy flag is set
deploy = "--deploy" in ARGS

# These are the targets we support right now:
#   x86_64-w64-mingw32
#   x86_64-apple-darwin14
#   aarch64-apple-darwin20
#   x86_64-linux-gnu
#   x86_64-linux-musl
#   aarch64-linux-gnu
#   aarch64-linux-musl
#   riscv64-linux-gnu
#   riscv64-linux-musl
#   powerpc64le-linux-gnu
#
# Not supported:
#  i686: OCaml 5.0 dropped support for 32-bit platforms
#  freebsd: `POSIX threads are required but not supported on this platform`

# The first thing we're going to do is to install Rust for all targets into a single prefix
script = raw"""
cd ${WORKSPACE}/srcdir/ocaml
git submodule update --init

# Apply patches
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# OCaml is not relocatable yet, meaning we have to configure it with actual directory it'll
# end up in as the prefix (`/opt/$target`). However, BB expects things in $prefix, so use
# some rsync shenanigans to figure out the changes made by the script here.
# This should improve in the future: https://github.com/ocaml/RFCs/pull/53
# Alternatively, consider using the https://github.com/dra27/ocaml repository
# (currently not possibly due to the cross-compilation patches, but should work on 5.4).
runtime_prefix=/opt/$target
rsync --archive $runtime_prefix/ ${WORKSPACE}/initial_prefix/

# unset compiler env vars so that configure can detect them properly
unset CC CXX LD STRIP AS


## host compiler & tools

if [[ "${target}" == "${MACHTYPE}" ]]; then
    ./configure --prefix=${runtime_prefix}
    make -j${nproc}
    make install
else
    ./configure --prefix=${runtime_prefix}/host --build=${MACHTYPE} --host=${MACHTYPE}
    make -j${nproc}
    make install
    export PATH=${runtime_prefix}/host/bin:$PATH
fi

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


## cross compiler

if [[ "${target}" != "${MACHTYPE}" ]]; then
    cd ${WORKSPACE}/srcdir/ocaml
    make distclean

    # Build a cross-compiler
    ./configure --prefix=${runtime_prefix} --build=${MACHTYPE} --host=${MACHTYPE} --target=${target}
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
                target=$(readlink $bin)
                rm $bin
                ln -s $(basename ${target} .exe) ${runtime_prefix}/bin/$(basename ${bin} .exe)

            # if this is a file, simply rename it
            elif [[ -f $bin ]]; then
                mv $bin ${runtime_prefix}/bin/$(basename ${bin} .exe)
            fi
        done
    fi

    # Replace target compiler binaries with host ones
    # XXX: it isn't great to "pollute" a cross-compiled prefix with host binaries...
    #      can we not ship both, and have `dune -x` pick the appropriate binary?
    for bin in ocamlrun ocamlrund ocamlruni ocamlyacc; do
        rm -f $runtime_prefix/bin/$bin${exeext}
        cp $runtime_prefix/host/bin/$bin $runtime_prefix/bin
    done

    # Replace target compiler libraries (which the interpreter uses) with host ones
    rm -rf $runtime_prefix/lib/ocaml/stublibs/*
    cp $runtime_prefix/host/lib/ocaml/stublibs/* $runtime_prefix/lib/ocaml/stublibs
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

name = "OCaml"
compiler_target = try
    parse(Platform, ARGS[end])
catch
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))

# Build the tarballs
ndARGS, deploy_target = find_deploy_arg(ARGS)
build_info = build_tarballs(ndARGS, name, version, sources, script, Platform[compiler_target], products, dependencies;
                            skip_audit=true, julia_compat="1.6", preferred_gcc_version=v"5")

build_info = Dict(host_platform => first(values(build_info)))

# Upload the artifacts (if requested)
if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info; target=compiler_target)
end
