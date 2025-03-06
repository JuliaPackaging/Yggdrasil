# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "systemd"
version = v"256.7"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/systemd/systemd",
              "7635d01869ba325b9cf450923c8f13912b7ca536")
]

# Bash recipe for building across all platforms
script = raw"""
# check if we need to use a more recent glibc
if [[ -f "$prefix/usr/include/sched.h" ]]; then
    GLIBC_ARTIFACT_DIR=$(dirname $(dirname $(dirname $(realpath $prefix/usr/include/sched.h))))
    rsync --archive ${GLIBC_ARTIFACT_DIR}/ /opt/${target}/${target}/sys-root/
fi

cd systemd
install_license LICENSE.GPL2

# build-time dependencies that aren't packaged as JLLs
apk add coreutils
pip install jinja2

meson --cross-file=${MESON_TARGET_TOOLCHAIN} build \
    -Dmode=release \
    -Dresolve=false -Dnss-resolve=disabled \
    -Dmachined=false -Dnss-mymachines=disabled \
    -Dnss-myhostname=false -Dnss-systemd=false \
    -Dtests=false
ninja -C build -j${nproc}

# we only care about libsystemd, so install to a temporary prefix and copy what we need
meson install -C build --destdir "/tmp/prefix"
cd /tmp/prefix
# XXX: how is there a workspace/destdir dir there?
#      maybe this is because busybox's realpath doesn't support --relative
cd workspace/destdir
cp -ar lib/lib* $libdir
cp -ar include/* $includedir
cp -ar share/pkgconfig $prefix/share
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(Sys.islinux, platforms)
filter!(p -> libc(p) == "glibc", platforms)

# some platforms need a newer glibc, because the default one is too old
glibc_platforms = filter(platforms) do p
    libc(p) == "glibc" && proc_family(p) in ["intel", "power"]
end

# The products that we will ensure are always built
products = [
    LibraryProduct("libsystemd", :libsystemd),
    LibraryProduct("libudev", :libudev)
]

# Dependencies that must be installed before this package can be built.
dependencies = [
    # systemd requires glibc 2.16. we only package glibc 2.17,
    # which isn't compatible with current Linux kernel headers,
    # so use the next packaged version
    BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.19");
                    platforms=glibc_platforms),

    HostBuildDependency("gperf_jll"),

    # libsystemd dependencies
    Dependency("libcap_jll"),
    Dependency("Libgcrypt_jll"),
    Dependency("P11Kit_jll"),
    Dependency("Lz4_jll"),
    Dependency("XZ_jll"),
    Dependency("Zstd_jll"),

    # additional dependencies for building executables
    Dependency("Libmount_jll"),
    #Dependency("Bzip2_jll"),
    #Dependency("Zlib_jll"),
    #Dependency("acl_jll"),
    #Dependency("PCRE2_jll"),
    #Dependency("Glib_jll"),
    #Dependency("Dbus_jll"),
    #Dependency("xkbcommon_jll"),
    #Dependency("OpenSSL_jll"; compat="1.1.10"),
    #Dependency("XSLT_jll"),
    #Dependency("Libbpf_jll"),
    #Dependency("LibCURL_jll"),
    #Dependency("libidn2_jll"),
    #Dependency("libmicrohttpd_jll"),
    #Dependency("Elfutils_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8", dont_dlopen=true)
