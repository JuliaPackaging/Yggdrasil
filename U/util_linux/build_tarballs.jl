# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "util_linux"
version = v"2.35.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.35/util-linux-2.35.tar.gz", "98acab129a8490265052e6c1e033ca96d68758a13bb7fcd232c06bf16cc96238")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd util-linux-2.35
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-makeinstall-chown
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf)
]


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
    ExecutableProduct("col", :col),
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
    Dependency(PackageSpec(name="Gettext_jll", uuid="78b55507-aeef-58d4-861c-77aaff3498b1"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
