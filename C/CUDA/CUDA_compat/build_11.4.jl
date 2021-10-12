driver = "470.57.02"

sources_linux_x86 = [
    FileSource("https://us.download.nvidia.com/tesla/$driver/NVIDIA-Linux-x86_64-$driver.run",
               "55d7ae104827faa79e975321fe2b60f9dd42fbff65642053443c0e56fdb4c47d", "installer.run")
]
sources_linux_ppc64le = [
    FileSource("https://us.download.nvidia.com/tesla/$driver/NVIDIA-Linux-ppc64le-$driver.run",
               "f430c6f898e0e2e1530e75f3770a29fd6b4e5628fea0b305fdd501a1a951b067", "installer.run")
]
sources_linux_aarch64 = [
    FileSource("https://us.download.nvidia.com/tesla/$driver/NVIDIA-Linux-aarch64-$driver.run",
               "4b3e51963b88e8de304a6bca68c64954844ed490156a28483e9272eb79a00451", "installer.run")
]

if should_build_platform("x86_64-linux-gnu-cuda+11.4")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_x86, script,
                   [Platform("x86_64", "linux"; cuda="11.4")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true)
end

if should_build_platform("powerpc64le-linux-gnu-cuda+11.4")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Platform("powerpc64le", "linux"; cuda="11.4")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true)
end

if should_build_platform("aarch64-linux-gnu-cuda+11.4")
    build_tarballs(ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux"; cuda="11.4")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true)
end
