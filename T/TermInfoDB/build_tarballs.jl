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

# Adopting the wisdom of https://mywiki.wooledge.org/ParsingLs (🙏 Mosè)
shopt -s nullglob

# Install `tree` to get an overview of what's going to be included in the JLL
apk update
apk add tree

gunzip terminfo-*
mkdir -p "${prefix}/share/terminfo"
tic -sx -o "${prefix}/share/terminfo" ./terminfo-*

# The terminfo filesystem-based database contains both upper- and lowercase directory
# names, which presents a problem for case-insensitive filesystems. Let's rename all
# files and directories to lowercase, dealing with conflicts by overwriting and hoping
# for the best.
pushd "${prefix}/share/terminfo/"
for dir in *; do
    lcdir="${dir,,}"
    mkdir -vp "${lcdir}"
    for file in ${dir}/*; do
        lcfile="${file,,}"
        if [ "${dir}/${file}" = "${lcdir}/${lcfile}" ]; then
            # Already all lowercase, nothing to do
            continue
        fi
        mv -fv "${dir}/${file}" "${lcdir}/${lcfile}.TEMP"
        rm -fv "${lcdir}/${lcfile}"
        mv -fv "${lcdir}/${lcfile}.TEMP" "${lcdir}/${lcfile}"
        if [ -e "${dir}/${file}" ] || [ -e "${lcdir}/${lcfile}.TEMP" ]; then
            echo "ERROR: '${dir}/${file}' not successfully renamed to lowercase!!!"
            exit 1
        fi
    done
    if [ -z "$(ls -A "${dir}")" ]; then
        rm -rfv "${dir}"
    fi
done
tree
popd

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
