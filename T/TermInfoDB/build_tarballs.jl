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

gunzip terminfo-*
mkdir -p "${prefix}/share/terminfo"
tic -sx -o "${prefix}/share/terminfo" ./terminfo-*

pushd "${prefix}/share/terminfo/"

# The terminfo filesystem-based database contains both upper- and lowercase directory
# names, which presents a problem for case-insensitive filesystems. Let's rename all
# files and directories to lowercase. Unfortunately, we can't just `mv` the filename
# to its lowercase counterpart because many of these files, including but not limited
# to those whose names differ only by case, are actually hard links to one another
# (they have the same inode) so `mv` sees it as a no-op and just does nothing.
# Hence... this.
for dir in *; do
    lcdir="${dir,,}"
    mkdir -p "${lcdir}"
    for file in ${dir}/*; do
        file=$(basename "${file}")
        lcfile="${file,,}"
        if [ "${dir}/${file}" = "${lcdir}/${lcfile}" ]; then
            # Already all lowercase, nothing to do
            continue
        fi
        mv -f "${dir}/${file}" "${lcdir}/${lcfile}.TEMP"
        rm -f "${lcdir}/${lcfile}"
        mv -f "${lcdir}/${lcfile}.TEMP" "${lcdir}/${lcfile}"
        if [ -e "${dir}/${file}" ] || [ -e "${lcdir}/${lcfile}.TEMP" ]; then
            echo "ERROR: '${dir}/${file}' not successfully renamed to lowercase!!!"
            exit 1
        fi
    done
    if [ -z "$(ls -A "${dir}")" ]; then
        rm -rf "${dir}"
    fi
done

# I'm not about to list the entire contents out as `FileProduct`s, so we'll do our
# own mini-audit by checking that the expected directories exist. We know each is
# non-empty based on the above.
dirs=(*)
expected=(1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x z)
if [ ! -z "$(echo ${dirs[@]} ${expected[@]} | tr ' ' '\n' | sort | uniq -u)" ]; then
    echo "ERROR: Build did not produce the expected set of directories!!!"
    exit 1
fi

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
