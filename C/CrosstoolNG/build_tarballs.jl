using BinaryBuilder2, Pkg

# We will build for Linux for the current host
host_linux = Platform(arch(HostPlatform()), "linux")

build_tarballs(;
    src_name = "CrosstoolNG",
    src_version = v"1.27.0",
    sources = [
        ArchiveSource("https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-1.27.0/crosstool-ng-1.27.0.tar.xz",
                      "0506ab98fa0ad6d263a555feeb2c7fff9bc24a434635d4b0cdff9137fe5b4477"),
        DirectorySource(joinpath(@__DIR__, "./bundled")),
    ],
    target_dependencies = [
        # BB2's auditor cannot resolve libraries from BB1-built JLLs, and General's
        # Zlib, Ncurses and Readline JLLs are all BB1-built.
        JLLSource(
            "Zlib_jll";
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                source="https://github.com/staticfloat/Zlib_jll.jl"
            ),
        ),
        JLLSource(
            "Ncurses_jll";
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                source="https://github.com/staticfloat/Ncurses_jll.jl"
            ),
        ),
        JLLSource(
            "Readline_jll";
            repo=Pkg.Types.GitRepo(
                rev="bb2/GCCBootstrap-x86_64-linux-gnu",
                source="https://github.com/staticfloat/Readline_jll.jl"
            ),
        ),
    ],
    script = raw"""
    cd ${WORKSPACE}/srcdir/crosstool-ng*/

    # Eventually, it'd be nice to provide these via JLLs.
    apt update
    apt install -y texinfo help2man

    # Copy in our extra patches for all packages
    for package in ${WORKSPACE}/srcdir/patches/*; do
        package="$(basename "${package}")"
        for version in ${WORKSPACE}/srcdir/patches/${package}/*; do
            version="$(basename "${version}")"
            if [ ! -d packages/${package}/${version} ]; then
                continue
            fi
            cp -v ${WORKSPACE}/srcdir/patches/${package}/${version}/* packages/${package}/${version}/
        done
    done

    # Build crosstool-ng
    # The extra CFLAGS here are because the `kconfig/` directory of `crosstool-ng` doesn't
    # pay attention to the actual location of `ncurses`, it just directly looks for `panel.h`
    ./bootstrap
    CFLAGS="-I${includedir}/ncursesw" ./configure --prefix=${prefix}
    make -j${nproc} V=1
    make -j${nproc} install

    # Create wrapper script for `ct-ng` that automatically sets environment variables
    # to make it relocatable, otherwise it uses baked-in absolute paths. :(
    mv ${bindir}/ct-ng ${bindir}/ct-ng-real
    cat >${bindir}/ct-ng <<-'EOF'
    #!/bin/bash

    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    MAKE_ARGS=(
        CT_LIB_DIR="$(dirname ${SCRIPT_DIR})/share/crosstool-ng"
        CT_LIBEXEC_DIR="$(dirname ${SCRIPT_DIR})/libexec/crosstool-ng"
        CT_DOC_DIR="$(dirname ${SCRIPT_DIR})/share/doc/crosstool-ng"
    )
    make -rf "${SCRIPT_DIR}/ct-ng-real" "$@" "${MAKE_ARGS[@]}"
    EOF
    chmod +x ${bindir}/ct-ng
    sed -i.bak -e 's&export \([^[:space:]]*\)[[:space:]]* = /opt/host-tools/.*&export \1 = $(shell which \1)&' ${bindir}/ct-ng-real
    rm ${bindir}/ct-ng-real.bak
    sed -i.bak -e 's&export \([^[:space:]]*\)="/opt/host-tools/.*"&export \1="$(which \1)"&' ${prefix}/share/crosstool-ng/paths.sh
    rm ${prefix}/share/crosstool-ng/paths.sh.bak

    """,
    platforms = [host_linux],
    products = [
        ExecutableProduct("ct-ng", :ct_ng),
    ],
)
