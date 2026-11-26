# Sources required for all builds
sources = [
    ArchiveSource("https://gitlab.com/libxc/libxc/-/archive/$(version)/libxc-$(version).tar.bz2",
                  "3915fac94416e4c415534223ea492ad2663f928acf27e98662c861b094a6c306"),
]

# Disable unsupported platforms
function remove_unsupported_platforms(platforms)
    filter(platforms) do p
        # Internal compiler error in work_gga_inc.c/work_mgga_inc.c
        Sys.islinux(p) && arch(p) == "aarch64" && libgfortran_version(p) <= v"4" && return false

        true
    end
end
