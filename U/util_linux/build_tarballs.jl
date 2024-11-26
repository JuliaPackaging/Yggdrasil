# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "util_linux"
version_string = "2.40.2"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v$(version.major).$(version.minor)/util-linux-$(version_string).tar.xz",
                  "d78b37a66f5922d70edf3bdfb01a6b33d34ed3c3cafd6628203b2a2b67c8e8b3"),
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
    LibraryProduct("libblkid", :libblkid),
    LibraryProduct("libfdisk", :libfdisk),
    LibraryProduct("liblastlog2", :liblastlog2),
    LibraryProduct("libmount", :libmount),
    LibraryProduct("libsmartcols", :libsmartcols),
    LibraryProduct("libuuid", :libuuid),
    ExecutableProduct("addpart", :addpart, "sbin"),
    ExecutableProduct("agetty", :agetty, "sbin"),
    ExecutableProduct("blkdiscard", :blkdiscard, "sbin"),
    ExecutableProduct("blkid", :blkid, "sbin"),
    ExecutableProduct("blkzone", :blkzone, "sbin"),
    ExecutableProduct("blockdev", :blockdev, "sbin"),
    ExecutableProduct("cal", :cal),
    ExecutableProduct("chcpu", :chcpu, "sbin"),
    ExecutableProduct("chmem", :chmem),
    ExecutableProduct("choom", :choom),
    ExecutableProduct("chrt", :chrt),
    # ExecutableProduct("col", :col),   # `col` requires glibc and is not built on musl systems
    ExecutableProduct("colcrt", :colcrt),
    ExecutableProduct("colrm", :colrm),
    ExecutableProduct("column", :column),
    ExecutableProduct("ctrlaltdel", :ctrlaltdel, "sbin"),
    ExecutableProduct("delpart", :delpart, "sbin"),
    ExecutableProduct("dmesg", :dmesg),
    ExecutableProduct("eject", :eject),
    ExecutableProduct("exch", :exch),
    ExecutableProduct("enosys", :enosys),
    ExecutableProduct("fallocate", :fallocate),
    ExecutableProduct("fdformat", :fdformat, "sbin"),
    ExecutableProduct("fdisk", :fdisk, "sbin"),
    ExecutableProduct("fincore", :fincore),
    ExecutableProduct("findfs", :findfs, "sbin"),
    ExecutableProduct("findmnt", :findmnt),
    ExecutableProduct("flock", :flock),
    ExecutableProduct("fsck", :fsck, "sbin"),
    ExecutableProduct("fsck.cramfs", :fsck_cramfs, "sbin"),
    ExecutableProduct("fsck.minix", :fsck_minix, "sbin"),
    ExecutableProduct("fsfreeze", :fsfreeze, "sbin"),
    ExecutableProduct("fstrim", :fstrim, "sbin"),
    ExecutableProduct("getopt", :getopt),
    ExecutableProduct("hardlink", :hardlink),
    ExecutableProduct("hexdump", :hexdump),
    ExecutableProduct("hwclock", :hwclock, "sbin"),
    ExecutableProduct("ionice", :ionice),
    ExecutableProduct("ipcmk", :ipcmk),
    ExecutableProduct("ipcrm", :ipcrm),
    ExecutableProduct("ipcs", :ipcs),
    ExecutableProduct("isosize", :isosize),
    ExecutableProduct("kill", :kill_bin),
    ExecutableProduct("last", :last_bin),
    ExecutableProduct("lastlog2", :lastlog2),
    ExecutableProduct("ldattach", :ldattach, "sbin"),
    ExecutableProduct("logger", :logger),
    ExecutableProduct("look", :look),
    ExecutableProduct("losetup", :losetup, "sbin"),
    ExecutableProduct("lsblk", :lsblk),
    ExecutableProduct("lsclocks", :lsclocks),
    ExecutableProduct("lscpu", :lscpu),
    ExecutableProduct("lsipc", :lsipc),
    ExecutableProduct("lslocks", :lslocks),
    ExecutableProduct("lslogins", :lslogins),
    ExecutableProduct("lsmem", :lsmem),
    ExecutableProduct("lsns", :lsns),
    ExecutableProduct("mcookie", :mcookie),
    ExecutableProduct("mesg", :mesg),
    ExecutableProduct("mkfs", :mkfs, "sbin"),
    ExecutableProduct("mkfs.bfs", :mkfs_bfs, "sbin"),
    ExecutableProduct("mkfs.cramfs", :mkfs_cramfs, "sbin"),
    ExecutableProduct("mkfs.minix", :mkfs_minix, "sbin"),
    ExecutableProduct("mkswap", :mkswap, "sbin"),
    ExecutableProduct("mount", :mount),
    ExecutableProduct("mountpoint", :mountpoint),
    ExecutableProduct("namei", :namei),
    ExecutableProduct("nologin", :nologin, "sbin"),
    ExecutableProduct("nsenter", :nsenter),
    ExecutableProduct("partx", :partx, "sbin"),
    ExecutableProduct("pivot_root", :pivot_root, "sbin"),
    ExecutableProduct("prlimit", :prlimit),
    ExecutableProduct("raw", :raw, "sbin"),
    ExecutableProduct("readprofile", :readprofile, "sbin"),
    ExecutableProduct("rename", :rename_bin),
    ExecutableProduct("renice", :renice),
    ExecutableProduct("resizepart", :resizepart, "sbin"),
    ExecutableProduct("rev", :rev),
    ExecutableProduct("rfkill", :rfkill, "sbin"),
    ExecutableProduct("rtcwake", :rtcwake, "sbin"),
    ExecutableProduct("script", :script),
    ExecutableProduct("scriptlive", :scriptlive),
    ExecutableProduct("scriptreplay", :scriptreplay),
    ExecutableProduct("setarch", :setarch),
    ExecutableProduct("setpgid", :setpgid),
    ExecutableProduct("setsid", :setsid),
    ExecutableProduct("sfdisk", :sfdisk, "sbin"),
    ExecutableProduct("sulogin", :sulogin, "sbin"),
    ExecutableProduct("swaplabel", :swaplabel, "sbin"),
    ExecutableProduct("swapoff", :swapoff, "sbin"),
    ExecutableProduct("swapon", :swapon, "sbin"),
    ExecutableProduct("switch_root", :switch_root, "sbin"),
    ExecutableProduct("taskset", :taskset),
    ExecutableProduct("umount", :umount),
    ExecutableProduct("unshare", :unshare),
    ExecutableProduct("utmpdump", :utmpdump),
    ExecutableProduct("uuidd", :uuidd, "sbin"),
    ExecutableProduct("uuidgen", :uuidgen),
    ExecutableProduct("uuidparse", :uuidparse),
    ExecutableProduct("wall", :wall),
    ExecutableProduct("wdctl", :wdctl),
    ExecutableProduct("whereis", :whereis),
    ExecutableProduct("wipefs", :wipefs, "sbin"),
    ExecutableProduct("zramctl", :zramctl, "sbin"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SQLite_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
