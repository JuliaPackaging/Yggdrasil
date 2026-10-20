# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
# Inside julia, run once: using Pkg; Pkg.add("BinaryBuilder")
# Example: julia build_tarballs.jl --verbose --debug x86_64-linux-gnu

using BinaryBuilder, Pkg

name = "PARI"
version = v"2.17.3"

sources = [
    ArchiveSource(
        "https://pari.math.u-bordeaux.fr/pub/pari/unix/pari-$(version).tar.gz",
        "8d9c4fcd584c468d27e0f23c36836587284452094c4b1c404c20c4b810462dcb",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/pari-*

# --- Cross-compilation shim for PARI's Configure --------------------------
# PARI's Configure probes the target by COMPILING and then RUNNING small C
# programs (config/ansi.c, config/gnu.c, config/endian.c, config/gmp_version.c).
# Under BinaryBuilder everything is cross-compiled, so those probe binaries are
# foreign and cannot execute on the builder; Configure then aborts with
# "C compiler does not work" (this is what broke aarch64, darwin, ... ).
# Configure honours a $RUNTEST hook precisely for cross-compilation, so we
# point it at a shim that answers each probe from values we already know for
# ${target}. Note: the has_*.c feature probes use link-only tests already, so
# RUNTEST is the *only* thing standing between PARI and cross-compilation.
if [ "${nbits}" -eq 64 ]; then
    pari_endian="-"          # config/endian.c: '-'  => sizeof(long) == 8
else
    pari_endian="1"          # config/endian.c: '1'  => 32-bit IEEE little-endian
fi
# config/gmp_version.c only needs a non-empty, non-"unsupported" string.
pari_gmp_version=$(awk '/define __GNU_MP_VERSION /         {maj=$3}
                        /define __GNU_MP_VERSION_MINOR /    {min=$3}
                        /define __GNU_MP_VERSION_PATCHLEVEL /{pat=$3}
                        END {print maj"."min"."pat}' "${prefix}/include/gmp.h")
[ -n "${pari_gmp_version}" ] && [ "${pari_gmp_version}" != ".." ] || pari_gmp_version="6.0.0"

cat > "${WORKSPACE}/pari_runtest" <<EOF
#!/bin/sh
# Configure calls us as: pari_runtest <freshly-built-probe-binary>.
# The probe binary's name encodes which check Configure is performing.
case "\$1" in
    *-endian*) echo "${pari_endian}" ;;
    *-gmp*)    echo "${pari_gmp_version}" ;;
    *)         : ;;   # ansi.c / gnu.c: a 0 exit status is all Configure needs
esac
exit 0
EOF
chmod +x "${WORKSPACE}/pari_runtest"
export RUNTEST="${WORKSPACE}/pari_runtest"

# PARI's Configure expects target_host in the form "arch-osname"
# (its config/get_archos splits on the LAST dash). BB triplets like
# x86_64-linux-gnu have an extra component, so we normalise them.
case "${target}" in
    *-linux-*)         pari_host="$(echo ${target} | cut -d- -f1)-linux" ;;
    *-apple-darwin*)   pari_host="$(echo ${target} | cut -d- -f1)-darwin" ;;
    *-freebsd*)        pari_host="$(echo ${target} | cut -d- -f1)-freebsd" ;;
    *-mingw32*)        pari_host="$(echo ${target} | cut -d- -f1)-mingw" ;;
    *)                 pari_host="${target}" ;;
esac

# BinaryBuilder exports LD pointing at the raw `ld`. PARI's Configure honours
# $LD and would then link executables with `ld` directly, bypassing the
# compiler driver. That is harmless on Linux (the C-library symbols resolve
# transitively through libpari's NEEDED entries) but fatal on macOS, where
# libSystem never lands on the link line (undefined ___stdinp/___stderrp/...).
# Unset LD so Configure falls back to LD=$CC and links via the driver.
unset LD

# Cross-compile friendly Configure invocation.
#   --kernel=gmp  : skip native CPU kernel autodetect, always use GMP kernel
#   --graphic=none: do not link any plotting backend
#   --without-readline : no readline dep (libpari is what JLL consumers want)
#   --mt=pthread  : enable parboundary threading (matches Nemo/Hecke usage)
./Configure \
    --prefix=${prefix} \
    --host=${pari_host} \
    --with-gmp=${prefix} \
    --without-readline \
    --graphic=none \
    --kernel=gmp \
    --mt=pthread \
    --time=clock_gettime

# Configure creates an Oxxx-pthread/ directory; cd in and build.
cd O*
make -j${nproc} gp
make install
make install-lib-dyn

install_license ${WORKSPACE}/srcdir/pari-*/COPYING
"""

# With the RUNTEST shim and the LD fix above, PARI's Configure cross-compiles
# cleanly on every platform, Windows/mingw included.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gp", :gp),
    LibraryProduct("libpari", :libpari),
    # pari.desc: the machine-readable database of every GP function (name, C
    # symbol, prototype, help text). `make install` always installs it under
    # share/pari/ (install-cfg target). Declaring it as a product exposes it
    # as PARI_jll.pari_desc and makes the audit fail loudly if a future PARI
    # release stops shipping it -- it is the source consumed by auto-generated
    # high-level wrappers (e.g. a Julia binding generator, like cypari2's).
    FileProduct("share/pari/pari.desc", :pari_desc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version = v"10")
