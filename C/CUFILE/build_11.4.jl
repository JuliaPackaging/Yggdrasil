cuda = "11-4"
deb = "1"
platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        FileSource("https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libcufile-$(cuda)_$(full_version)-$(deb)_amd64.deb",
                "6b3a07e02c687ad71ef3f52f45ef2b94b336ed087a28da4124fe38e6320843e3"),
        FileSource("https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/libcufile-dev-$(cuda)_$(full_version)-$(deb)_amd64.deb",
                "bc8c1f01206e1e0bedafacd7cf17f4c79aaa0a2f68cea7ba89b962740264cd7d")],
)
