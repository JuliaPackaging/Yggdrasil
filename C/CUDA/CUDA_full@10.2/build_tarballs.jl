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
    # Expected install order for cuda-toolkit-10-2, i.e. output from `apt-get -s install --no-install-recommends cuda-toolkit-10-2` (using source: "deb https://repo.download.nvidia.com/jetson/common r32.5 main")
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-license-10-2_10.2.89-1_arm64.deb", "8a862acbff5b33904bfe7ec3e92a553a8312da1db9f651b6cfe14db137a139ce"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvdisasm-10-2_10.2.89-1_arm64.deb", "9523033692cca5a2b29cd69942d69036deedacb8eb3273395662f6024b2c27f9"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cuobjdump-10-2_10.2.89-1_arm64.deb", "719b32f039cd8ed6123e1f9e3fa9badcf4c6ba5ac4a0b24a97d2db88e0764e1e"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-gdb-10-2_10.2.89-1_arm64.deb", "d3fef316b7d5b215cf11ff0190c69d9e8a2652b9dd37f454c7350110954e3496"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvprof-10-2_10.2.89-1_arm64.deb", "54d96b9cdba5a53da92b2cdaada27ec7a886b3a6a29e7d33b5fdf429ad788681"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-memcheck-10-2_10.2.89-1_arm64.deb", "f8f498108e1e4e3fdc40a1cb80cec44bb3da987b2160a3128d3bcf85a8533bbf"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cudart-10-2_10.2.89-1_arm64.deb", "2a718596cf1162bf0076d4ec6db52a5f7c3617b7ab7cd243887376e841a99915"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-driver-dev-10-2_10.2.89-1_arm64.deb", "c1c55ba59d8a28a7d56800504c65683a4d392893f35d08ec7bddf6b45efda468"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cudart-dev-10-2_10.2.89-1_arm64.deb", "5aa2bf1e8e9d467dacbff778b0d2d4a7bd31077a443b7a49711cc798562ea37d"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-misc-headers-10-2_10.2.89-1_arm64.deb", "e92834f576241295c74393b478cb7121d9e20cb3454aed26c464c3523eaeadde"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvcc-10-2_10.2.89-1_arm64.deb", "1a0ea57d4c1b1d9394d7e4f6ab94baa2aa49883f4ba2d59a60b750bb88d0fdeb"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cupti-10-2_10.2.89-1_arm64.deb", "319771f42db1d9a4a273bc5ff753148247ece9cf7544d2008d57d9061e6964f9"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cupti-dev-10-2_10.2.89-1_arm64.deb", "3bd27507b8eef4ae9d5faf8671e8843ef7bd4cede82dc76a8e6519390e22a5dc"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvtx-10-2_10.2.89-1_arm64.deb", "b4f9dedf0c21dbc75daadbabfde6aa17a73b6bdad0d5a18fae3da6e9717bfc99"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-command-line-tools-10-2_10.2.89-1_arm64.deb", "7425afa9751b073b709f969149babb65411e2ab96bbe1744af0d89a517a6f1a2"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvprune-10-2_10.2.89-1_arm64.deb", "1e04820f53fb96b737c6b5d92ae2c1c54414e84a87ae9a55a00fc78c05e4e33f"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-compiler-10-2_10.2.89-1_arm64.deb", "cf15fd18669b88dfd9e49be6e8189e03936ce993be47dfc88b99d1b3d86d3a6d"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cufft-10-2_10.2.89-1_arm64.deb", "7d06a0bdd16b16c2384de79e488cde5bb580b3bc9ee46bd1e23d17ce6d260e01"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cufft-dev-10-2_10.2.89-1_arm64.deb", "239060c552e98511b8a752127c57bd86cd1261af5062b99f85d94a12ef61d876"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-curand-10-2_10.2.89-1_arm64.deb", "1cf024814383a2ec21e562e1e89809050dbae36bceed6ee276affe03185ca266"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-curand-dev-10-2_10.2.89-1_arm64.deb", "f6594cd55b89a4e45ca3a382cef99c6bd3d2efb7ab222a82f261a79cc9e066ce"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cusolver-10-2_10.2.89-1_arm64.deb", "ede4930b8a7d8098590b3691785cf225fdbb08e3cb7853ca8f0ffc7313e89b3f"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cusolver-dev-10-2_10.2.89-1_arm64.deb", "e3d786efc6d92e24c2527a2a76685de4cfc92e609a3b6ab1258cc820a5c867e4"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cusparse-10-2_10.2.89-1_arm64.deb", "459f9e41ac458eef3c94ba0a5d367182af83c070454d9e38b3565252c039a827"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-cusparse-dev-10-2_10.2.89-1_arm64.deb", "3a9ccd17e6916fda5cede14c206a8199fdba27f1118947a1f31cbf33132241df"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvrtc-10-2_10.2.89-1_arm64.deb", "fe9cc7cbdab29035371e5f77d190aecd97bbf31ca66b3f62612bf62580417b16"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvrtc-dev-10-2_10.2.89-1_arm64.deb", "5c3bd9bc84170ec0c3465444409e7912046e2523e6a18d331b53901c0e57d229"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cublas/libcublas10_10.2.2.89-1_arm64.deb", "d0299b139a163136432dfb2c028769944b6c5636ad9238614860c196a1c91aea"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cublas/libcublas-dev_10.2.2.89-1_arm64.deb", "5fa7e3e8fe266fdea7e91778610b7e8d3d85d8950875a4915ce3626c9e564365"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-npp-10-2_10.2.89-1_arm64.deb", "a01a204e6afefb0072424817c7133c5c18a9f3996fbf48f0b31297cb7c07e1ac"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-npp-dev-10-2_10.2.89-1_arm64.deb", "4d572a2472564f5008c3cfe9b24dbef765a1531a73c43436c66a146b4d16cace"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvgraph-10-2_10.2.89-1_arm64.deb", "f800974ac6cb3fb6595a08e613fc0f376d7b91f43eed1b5306b0496f9588e441"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvgraph-dev-10-2_10.2.89-1_arm64.deb", "cc2d9897c54f27a20f90bea5df391875b3f8163ec69745fb7546c1ce57e1d718"),
    # FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda-samples/cuda-samples-10-2_10.2.89-1_arm64.deb", "121e273d8586bde904ceeab72a603a86d781f3bac6d3a21732703ca2ca9ec528"),
    # FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-documentation-10-2_10.2.89-1_arm64.deb", "746f675b08f29cdf7d9fe39edb325a960ae29106da805369b8dc509e72ec2329"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-libraries-10-2_10.2.89-1_arm64.deb", "71309637bbc86b3d7f014c5ba5da709b88f69dfc0710aa8caa661b3aa40a51b4"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-libraries-dev-10-2_10.2.89-1_arm64.deb", "9d3e1e4cf097f6e04c7f881b4af1a54c52552fb2828f73f7ae8fa5b9efe32d29"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-nvml-dev-10-2_10.2.89-1_arm64.deb", "c8743e69c84a432c5e6dea6edfcacf1bb6b09b028bee61c8aece7a41d0447265"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-tools-10-2_10.2.89-1_arm64.deb", "eeaae6a103cc5d950bf4e774a277d90286492df0e0815e161f7c12291c9aa5ba"),
    FileSource("https://repo.download.nvidia.com/jetson/common/pool/main/c/cuda/cuda-toolkit-10-2_10.2.89-1_arm64.deb", "47a1c8c8bde2c763396a68c38cc901217e1606bb536ec5880d4c072c4eee9073"),
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
    find $temp
    mv $temp/usr/local/cuda-10.2/* ${prefix}/cuda

    rsync -aOv --remove-source-files $temp/usr/include/ ${prefix}/cuda/targets/aarch64-linux/include/
    rsync -aOv --remove-source-files $temp/usr/lib/$target/ ${prefix}/cuda/targets/aarch64-linux/lib/

    # Move CUPTI into same paths as CUPTI on x86_64-linux-gnu
    mkdir $prefix/cuda/extras/CUPTI/{include,lib64}
    CUDA_TARGETS_REGEX='./usr/local/cuda-10.2/(targets/[^ ]+).*$'
    CUPTI_PKGS="cuda-cupti-10-2 cuda-cupti-dev-10-2"
    CUPTI_PATHS=""
    for CUPTI_PKG in $CUPTI_PKGS; do
        CUPTI_PATHS+=" "`dpkg-deb -c $CUPTI_PKG* | grep -E "$CUDA_TARGETS_REGEX" | sed -E -e "s#.*$CUDA_TARGETS_REGEX#\1#"`
    done
    for CUPTI_PATH in $CUPTI_PATHS; do
        CUPTI_PATH=$prefix/cuda/$CUPTI_PATH
        [ -f $CUPTI_PATH ] || [ -L $CUPTI_PATH ] && [[ $CUPTI_PATH == */include* ]] && mv -nv $CUPTI_PATH $prefix/cuda/extras/CUPTI/include
        [ -f $CUPTI_PATH ] || [ -L $CUPTI_PATH ] && [[ $CUPTI_PATH == */lib* ]] && mv -nv $CUPTI_PATH $prefix/cuda/extras/CUPTI/lib64
    done

    mv ${prefix}/cuda/doc/EULA.txt ${prefix}/cuda
    rmdir ${prefix}/cuda/doc
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
