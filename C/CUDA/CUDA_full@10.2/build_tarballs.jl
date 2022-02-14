using BinaryBuilder

include("../../../fancy_toys.jl")

name = "CUDA_full"
version = v"10.2.89"

sources_linux = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run",
               "560d07fdcf4a46717f2242948cd4f92c5f9b6fc7eae10dd996614da913d5ca11", "installer.run")
]
sources_macos = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_mac.dmg",
               "51193fff427aad0a3a15223b1a202a6c6f0964fcc6fb0e6c77ca7cd5b6944d20", "installer.dmg")
]
sources_windows = [
    FileSource("http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_441.22_win10.exe",
               "b538271c4d9ffce1a8520bf992d9bd23854f0f29cee67f48c6139e4cf301e253", "installer.exe")
]

sources_linux_aarch64 = [
    # Expected install order for cuda-toolkit-10-2 (provided build-essential was installed prior) - i.e. output from apt-get -s install --no-install-recommends cuda-toolkit-10-2
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-cudart/cuda-cudart-10-2_10.2.300-1_arm64.deb", "e3cd683965f7b2e4a13b27c58754443185dcc545d0f989e52c224840cfde48d1"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-cudart/cuda-driver-dev-10-2_10.2.300-1_arm64.deb", "5ea760773de2685acfac3931bcdc2eff3a18eceb28fc86f80061e215e9e81456"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-cudart/cuda-cudart-dev-10-2_10.2.300-1_arm64.deb", "d37a94a3fb858db2cf41cde1bcbe1042b9a66d4fd3fd30882805a478523acb18"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvcc/cuda-nvcc-10-2_10.2.300-1_arm64.deb", "86c138d6903fa35bb512414bbb98dfd519d3e5ee743dc846e9fb1aa42f7e0391"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-cupti/cuda-cupti-10-2_10.2.300-1_arm64.deb", "e2024cd43668e3102c6afd0767cfcbc107e49b5198fbb437591758b0c2c4f6f1"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-cupti/cuda-cupti-dev-10-2_10.2.300-1_arm64.deb", "731abaaf4c5ce24c4a4ecce6b1921b88662b70e57bffee0b20bbee9b17fc4353"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvdisasm/cuda-nvdisasm-10-2_10.2.300-1_arm64.deb", "6b9a6f123bc46d525abf351e8720fa6da5573fd9caeebe312590105bef71a146"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-cuobjdump/cuda-cuobjdump-10-2_10.2.300-1_arm64.deb", "1a6c02ae2786fadeac0888e8998d47e28282319b36909b6cdc3c0a546afa578a"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-gdb/cuda-gdb-10-2_10.2.300-1_arm64.deb", "662c7e43a4cce180f187cf5f2b00d8634d9276a6ecb415eeca638778e27c215f"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-memcheck/cuda-memcheck-10-2_10.2.300-1_arm64.deb", "2027d40d3302ecfbfa42790b365f8c097726d5a8b05fb7087971dec7e6bc1f35"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvprof/cuda-nvprof-10-2_10.2.300-1_arm64.deb", "882c05ec6d681980c1a6cc5afacd4c2a58e6d819cb1aa043ae16bb74f97a70f8"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvtx/cuda-nvtx-10-2_10.2.300-1_arm64.deb", "fe29d0a639620c161a732cdff520670142e986d795bb3f7afd7c06e41dca340e"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-command-line-tools-10-2/cuda-command-line-tools-10-2_10.2.460-1_arm64.deb", "76eb6e1bc49f5a08443ddf8f2b283b057cf16a8d907b033853ce316fa6c89fc5"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvprune/cuda-nvprune-10-2_10.2.300-1_arm64.deb", "c77f9f554932d7586d58c5cc77b62ae94f2c1a9779aac78fd8b89335b6ad35ba"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-compiler-10-2/cuda-compiler-10-2_10.2.460-1_arm64.deb", "9d2ccb1a43782e3b9728c35a81525f229fac1a4e422708da58c00e98e8fdcf1e"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvrtc/cuda-nvrtc-10-2_10.2.300-1_arm64.deb", "7118079394a22c6cedba1152f0a78ef7bb10ac26c1984ab8c4dcf82fe9f4e20c"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvrtc/cuda-nvrtc-dev-10-2_10.2.300-1_arm64.deb", "bdce95a7a30daf7d1a52a32385c1ee67a8f742126a2f24d82a7b7dd35d012f3f"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcusolver/libcusolver-10-2_10.3.0.300-1_arm64.deb", "31a32e7c7e439bc34331d32b93392d08de6c9893d5083865b93703509d6fb7d6"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcusolver/libcusolver-dev-10-2_10.3.0.300-1_arm64.deb", "c86b549b4501a8ddd451dd7f46ea55b79d548bd987aaa17f3af03813e4b90dba"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcublas/libcublas10_10.2.3.300-1_arm64.deb", "a4cde28215c01bce78fa7c3d09909afaec487142e1144646bd7ff043a5c6c1df"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcublas/libcublas-dev_10.2.3.300-1_arm64.deb", "f2575fd6c86c9aa8eed0e782d68122d9ba3d1422ebd6e6c06c71bea096c169db"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcufft/libcufft-10-2_10.1.2.300-1_arm64.deb", "661a91f35f2d148d938ca907484ebe48727b17f03a8cbb6992e60bb792738caf"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcufft/libcufft-dev-10-2_10.1.2.300-1_arm64.deb", "43bf089682f745397c7c72bb53ce6d962e2d24246e1e7e686fd8159d3ddf7ba1"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcurand/libcurand-10-2_10.1.2.300-1_arm64.deb", "45f2bbafdde70b8b8bcdc6f0625a2ab334632b6659f153224654d03e1776057b"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcurand/libcurand-dev-10-2_10.1.2.300-1_arm64.deb", "7da1321d221290c7c8dcf49bef8970712cb981d8f9a93f405a080364f1bf0b12"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcusparse/libcusparse-10-2_10.3.1.300-1_arm64.deb", "bd844b7a71adc76694caf5da4818ab03f207e3b7f23340aa2fe86909f799fb92"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libc/libcusparse/libcusparse-dev-10-2_10.3.1.300-1_arm64.deb", "898fab6cae719007fdf0c8ebb27825bc7dd03e48314297b2b60639b604fa6bc4"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libn/libnpp/libnpp-10-2_10.2.1.300-1_arm64.deb", "dc51dc218b7652680138ca236877d01ff0b65546d60a113276ded05f1fea967e"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/libn/libnpp/libnpp-dev-10-2_10.2.1.300-1_arm64.deb", "4c64992156eaeb982af504a41920a33df01c701286903d07fe23c1d20c902b38"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-samples/cuda-samples-10-2_10.2.300-1_arm64.deb", "bb7726194bac9252863da80ae13e4fdd7e69a657314cb8ff6edf8ba1cd789e2d"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-documentation/cuda-documentation-10-2_10.2.300-1_arm64.deb", "d8e8c62156516d5eb2dea0ba49abd1b5cecae010872e0e71650e97a1ccd2e005"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvgraph/cuda-nvgraph-10-2_10.2.300-1_arm64.deb", "88412a2eecdc5dc2f3db7f6f2dea3d13c234114b8f36ec0356d237190504748e"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-libraries-10-2/cuda-libraries-10-2_10.2.460-1_arm64.deb", "a09ecb11e6ccf1d44c4ba941de49e0b9be02f6d70ba7f2f5c8be06a9d50fc9d1"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvgraph/cuda-nvgraph-dev-10-2_10.2.300-1_arm64.deb", "f280b981d54745d24bd933c48eba76903f4174d13e38aae89454f29433355186"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-libraries-dev-10-2/cuda-libraries-dev-10-2_10.2.460-1_arm64.deb", "bb34c354f1b96c170c9d175c360741a098a1c4933abc9864d85df937005c57a8"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-nvml-dev/cuda-nvml-dev-10-2_10.2.300-1_arm64.deb", "70620354d37385ff1d34ac2d4f713ca3419d413103f90e385adb0e7112bec501"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-visual-tools-10-2/cuda-visual-tools-10-2_10.2.460-1_arm64.deb", "39fb8d2d529a3aee658a51bee429124900f55c8513a6427d4963722d37ef65ff"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-tools-10-2/cuda-tools-10-2_10.2.460-1_arm64.deb", "c9c099420ebe15cf385e3b23bcae44c6338bcbc04aba6011560539fa473730c8"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-toolkit-10-2/cuda-toolkit-10-2_10.2.460-1_arm64.deb", "4c047e83b805ce9d76cbc5a2de2177548d8a63cd025e03f944705bf653e82828")
]
sources_linux_aarch64_manifest = join([src.filename for src in sources_linux_aarch64], "\n")

script = """
if [[ \${target} == aarch64-linux-gnu ]]; then
    echo \"$(sources_linux_aarch64_manifest)\" >> \${WORKSPACE}/srcdir/aarch64-linux-gnu_install.manifest
fi
""" * raw"""
cd ${WORKSPACE}/srcdir

# use a temporary directory to avoid running out of tmpfs in srcdir on Travis
temp=${WORKSPACE}/tmpdir
mkdir ${temp}

apk add p7zip

mkdir ${prefix}/cuda
if [[ ${target} == x86_64-linux-gnu ]]; then
    sh installer.run --tmpdir="${temp}" --target "${temp}" --noexec
    cd ${temp}/builds/cuda-toolkit
    find .

    # clean-up
    rm -r libnsight libnvvp nsightee_plugins nsight-compute-2019.5.0 nsight-systems-2019.5.2 doc

    mv * ${prefix}/cuda
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    7z x installer.dmg 5.hfs -o${temp}
    cd ${temp}
    7z x 5.hfs
    tar -zxf CUDAMacOSXInstaller/CUDAMacOSXInstaller.app/Contents/Resources/payload/cuda_mac_installer_tk.tar.gz
    cd Developer/NVIDIA/CUDA-*/
    find .

    # clean-up
    rm -r libnsight libnvvp nsightee_plugins nsight-compute-2019.5.0 NsightSystems-2019.5.2.16 doc

    mv * ${prefix}/cuda
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    7z x installer.exe -o${temp}
    cd ${temp}
    find .

    mv EULA.txt ${prefix}/cuda

    for project in cuobjdump memcheck nvcc cupti nvdisasm curand cusparse npp cufft \
                   cublas cudart cusolver nvrtc nvgraph nvprof nvprune; do
        [[ -d ${project} ]] || { echo "${project} does not exist!"; exit 1; }
        cp -a ${project}/* ${prefix}/cuda
    done

    # NVIDIA Tools Extension Library
    7z x "CUDAVisualStudioIntegration/NVIDIA NVTX Installer.x86_64".*.msi -o${temp}/nvtx_installer
    find nvtx_installer
    for file in nvtx_installer/*.*_*; do
        mv $file $(echo $file | sed 's/\.\(\w*\)_.*/.\1/')
    done
    mv nvtx_installer/*.dll ${prefix}/cuda/bin
    mv nvtx_installer/*64_*.lib ${prefix}/cuda/lib/x64
    mv nvtx_installer/*32_*.lib ${prefix}/cuda/lib/Win32
    mv nvtx_installer/*.h ${prefix}/cuda/include

    # fixup
    chmod +x ${prefix}/cuda/bin/*.{exe,dll}

    # clean-up
    rm ${prefix}/cuda/*.nvi
elif [[ ${target} == aarch64-linux-gnu ]]; then
    apk add dpkg
    cat ${target}_install.manifest | xargs -t -Ideb_file dpkg-deb -x deb_file $temp
    cd $temp/usr/local/cuda-10.2
    find .

    # clean-up
    rm -r doc

    mv * ${prefix}/cuda
fi

cd ${prefix}/cuda
install_license EULA.txt
"""

products = Product[
    # this JLL isn't meant for use by Julia packages, but only as build dependency
]

dependencies = []

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux, script,
                   [Platform("x86_64", "linux")], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("x86_64-apple-darwin14")
    build_tarballs(non_reg_ARGS, name, version, sources_macos, script,
                   [Platform("x86_64", "macos")], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_windows, script,
                   [Platform("x86_64", "windows")], products, dependencies;
                   skip_audit=true)
end

if should_build_platform("aarch64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux")], products, dependencies;
                   skip_audit=true)
end
