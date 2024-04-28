# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "util_linux"
version_string = "2.40"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v$(version.major).$(version.minor)/util-linux-$(version_string).tar.xz",
                  "d57a626081f9ead02fa44c63a6af162ec19c58f53e993f206ab7c3a6641c2cd7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/util-linux-*
export CPPFLAGS="-I${includedir}"

configure_flags=()
if [[ ${nbits} == 32 ]]; then
   # We disable the year 2038 check because we don't have an alternative on the affected systems
   configure_flags+=(--disable-year2038)
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-makeinstall-chown --enable-fdformat ${configure_flags[@]}
make -j${nproc}
make install
"""

# Build only for Linux
platforms = filter(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("chmem", :chmem),
    ExecutableProduct("partx", :partx, "sbin"),
    ExecutableProduct("fallocate", :fallocate),
    ExecutableProduct("lsipc", :lsipc),
    ExecutableProduct("findfs", :findfs, "sbin"),
    ExecutableProduct("whereis", :whereis),
    ExecutableProduct("lslogins", :lslogins),
    ExecutableProduct("fsfreeze", :fsfreeze, "sbin"),
    ExecutableProduct("ctrlaltdel", :ctrlaltdel, "sbin"),
    ExecutableProduct("lsns", :lsns),
    ExecutableProduct("sfdisk", :sfdisk, "sbin"),
    ExecutableProduct("look", :look),
    ExecutableProduct("taskset", :taskset),
    ExecutableProduct("mkfs.bfs", :mkfs_bfs, "sbin"),
    ExecutableProduct("chrt", :chrt),
    ExecutableProduct("resizepart", :resizepart, "sbin"),
    ExecutableProduct("rfkill", :rfkill, "sbin"),
    ExecutableProduct("uuidparse", :uuidparse),
    ExecutableProduct("umount", :umount),
    ExecutableProduct("fsck.minix", :fsck_minix, "sbin"),
    ExecutableProduct("hwclock", :hwclock, "sbin"),
    ExecutableProduct("prlimit", :prlimit),
    ExecutableProduct("switch_root", :switch_root, "sbin"),
    LibraryProduct("libmount", :libmount),
    ExecutableProduct("mcookie", :mcookie),
    ExecutableProduct("fstrim", :fstrim, "sbin"),
    ExecutableProduct("delpart", :delpart, "sbin"),
    ExecutableProduct("fsck.cramfs", :fsck_cramfs, "sbin"),
    ExecutableProduct("fincore", :fincore),
    ExecutableProduct("hardlink", :hardlink),
    LibraryProduct("libuuid", :libuuid),
    ExecutableProduct("ipcs", :ipcs),
    ExecutableProduct("eject", :eject),
    ExecutableProduct("uuidd", :uuidd, "sbin"),
    ExecutableProduct("nologin", :nologin, "sbin"),
    ExecutableProduct("readprofile", :readprofile, "sbin"),
    ExecutableProduct("fdformat", :fdformat, "sbin"),
    ExecutableProduct("lscpu", :lscpu),
    # `col` requires glibc and thus doesn't work on musl systems
    # ExecutableProduct("col", :col),
    ExecutableProduct("addpart", :addpart, "sbin"),
    ExecutableProduct("sulogin", :sulogin, "sbin"),
    ExecutableProduct("getopt", :getopt),
    ExecutableProduct("rename", :rename_bin),
    ExecutableProduct("blockdev", :blockdev, "sbin"),
    ExecutableProduct("nsenter", :nsenter),
    ExecutableProduct("scriptreplay", :scriptreplay),
    ExecutableProduct("mkfs.cramfs", :mkfs_cramfs, "sbin"),
    ExecutableProduct("logger", :logger),
    ExecutableProduct("wall", :wall),
    ExecutableProduct("renice", :renice),
    ExecutableProduct("blkid", :blkid, "sbin"),
    LibraryProduct("libblkid", :libblkid),
    LibraryProduct("libfdisk", :libfdisk),
    ExecutableProduct("column", :column),
    ExecutableProduct("rtcwake", :rtcwake, "sbin"),
    ExecutableProduct("pivot_root", :pivot_root, "sbin"),
    ExecutableProduct("ipcrm", :ipcrm),
    ExecutableProduct("flock", :flock),
    ExecutableProduct("utmpdump", :utmpdump),
    ExecutableProduct("ionice", :ionice),
    ExecutableProduct("chcpu", :chcpu, "sbin"),
    ExecutableProduct("mesg", :mesg),
    ExecutableProduct("mkfs", :mkfs, "sbin"),
    ExecutableProduct("hexdump", :hexdump),
    ExecutableProduct("agetty", :agetty, "sbin"),
    ExecutableProduct("blkdiscard", :blkdiscard, "sbin"),
    ExecutableProduct("script", :script),
    ExecutableProduct("mountpoint", :mountpoint),
    ExecutableProduct("scriptlive", :scriptlive),
    ExecutableProduct("findmnt", :findmnt),
    ExecutableProduct("mkfs.minix", :mkfs_minix, "sbin"),
    ExecutableProduct("blkzone", :blkzone, "sbin"),
    ExecutableProduct("swapoff", :swapoff, "sbin"),
    ExecutableProduct("lslocks", :lslocks),
    ExecutableProduct("cal", :cal),
    ExecutableProduct("setarch", :setarch),
    ExecutableProduct("lsmem", :lsmem),
    ExecutableProduct("losetup", :losetup, "sbin"),
    ExecutableProduct("raw", :raw, "sbin"),
    ExecutableProduct("colrm", :colrm),
    ExecutableProduct("dmesg", :dmesg),
    ExecutableProduct("rev", :rev),
    ExecutableProduct("fsck", :fsck, "sbin"),
    ExecutableProduct("zramctl", :zramctl, "sbin"),
    ExecutableProduct("mkswap", :mkswap, "sbin"),
    ExecutableProduct("wipefs", :wipefs, "sbin"),
    ExecutableProduct("choom", :choom),
    LibraryProduct("libsmartcols", :libsmartcols),
    ExecutableProduct("namei", :namei),
    ExecutableProduct("mount", :mount),
    ExecutableProduct("setsid", :setsid),
    ExecutableProduct("swapon", :swapon, "sbin"),
    ExecutableProduct("ldattach", :ldattach, "sbin"),
    ExecutableProduct("swaplabel", :swaplabel, "sbin"),
    ExecutableProduct("ipcmk", :ipcmk),
    ExecutableProduct("unshare", :unshare),
    ExecutableProduct("isosize", :isosize),
    ExecutableProduct("colcrt", :colcrt),
    ExecutableProduct("last", :last_bin),
    ExecutableProduct("fdisk", :fdisk, "sbin"),
    ExecutableProduct("uuidgen", :uuidgen),
    ExecutableProduct("kill", :kill_bin),
    ExecutableProduct("lsblk", :lsblk),
    ExecutableProduct("wdctl", :wdctl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # TOOD: verify Gettext is actually needed at runtime
    Dependency("Gettext_jll", v"0.20.1"; compat="=0.20.1"),
    Dependency("SQLite_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
