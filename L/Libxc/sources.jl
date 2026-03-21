# Sources required for all builds
sources = [
    ArchiveSource("https://gitlab.com/libxc/libxc/-/archive/$(version)/libxc-$(version).tar.gz",
                  "8d4e343041c9cd869833822f57744872076ae709a613c118d70605539fb13a77"),
]

# Disable unsupported platforms
function remove_unsupported_platforms(platforms)
    filter(platforms) do p
        # Internal compiler error in work_gga_inc.c/work_mgga_inc.c
        Sys.islinux(p) && arch(p) == "aarch64" && libgfortran_version(p) <= v"4" && return false

        true
    end
end
