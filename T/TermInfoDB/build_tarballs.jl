using BinaryBuilder

# This is based on https://www.freshports.org/misc/terminfo-db/
name = "TermInfoDB"
version = v"2023.12.9"

v = string(version.major, lpad(version.minor, 2, '0'), lpad(version.patch, 2, '0'))
sources = [
    FileSource("https://invisible-island.net/archives/ncurses/current/terminfo-$v.src.gz",
               "2debcf2fd689988d44558bcd8a26a104b96542ffc9540f19e2586b3aeecd1c79"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/
gunzip terminfo-*
mkdir -p "${prefix}/share/terminfo"
tic -sx -o "${prefix}/share/terminfo" ./terminfo-*

# When ignoring case, these files are duplicates of others. We'll remove them to ensure
# they don't cause trouble on case-insensitive filesystems
DUPS=(
    2/2621a
    e/eterm
    e/eterm-color
    h/hp2621a
    h/hp70092a
    l/lft-pc850
    n/ncr260vt300wpp
    n/ncrvt100wpp
    p/p12
    p/p12-m
    p/p12-m-w
    p/p12-w
    p/p14
    p/p14-m
    p/p14-m-w
    p/p14-w
    p/p4
    p/p5
    p/p7
    p/p8
    p/p8-w
    p/p9
    p/p9-8
    p/p9-8-w
    p/p9-w
)
for file in "${DUPS[@]}"; do
    rm -fv "${prefix}/share/terminfo/${file}"
done
# Remove empty directories
find "${prefix}/share/terminfo/" -type d -empty -print -delete

install_license "${WORKSPACE}/srcdir/COPYING"
"""

platforms = [AnyPlatform()]

# I'd rather not list out >2k individual `FileProduct`s so let's just call the entry
# for xterm our "product" and hope the rest are there
products = [
    FileProduct("share/terminfo/x/xterm", :terminfo_xterm),
]

dependencies = [
    HostBuildDependency("Ncurses_jll"),  # for `tic`
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
