using BinaryBuilder, Pkg

include("../../fancy_toys.jl")

name = "oneAPI_Support"
version = v"0.3.2"

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl", "aedfc12b88655449f52558b03ee3cf52f440a8f9")
]

# oneAPI 2024.0.0
platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp-cpp-rt-2024.0.0-intel_49819.tar.bz2",
            "22b4d8754399bab5790d282066697b8cc3c2f1cbcc1f4b2d340727a6d7aa2c35"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_impl_linux-64-2024.0.0-intel_49819.tar.bz2",
            "3790e698d3e7b65bc3ae09d9dd8a30325271e2ed4faa745d472ed4db01d0258b"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_linux-64-2024.0.0-intel_49819.tar.bz2",
            "9ab6468f7522e7b2a84e6f2b79664aea4ae4a928518c30688d1d1db1870cdc90"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/icc_rt-2024.0.0-intel_49819.tar.bz2",
            "2aae241f522fa2b9af449d87faf2469cbe8c149134d8a7a809bfd7a2b4743052"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lib-rt-2024.0.0-intel_49819.tar.bz2",
            "c0e0118ef321e4f0f5a8eac7ef04872ce538122eb8db2cb875d63bbc25520fd7"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lic-rt-2024.0.0-intel_49819.tar.bz2",
            "4c9b9784ae53f47781d11d7a507fa0ce3de150769e049042f148e4e1c14fab7d"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-opencl-rt-2024.0.0-intel_49819.tar.bz2",
            "618506a21a5ad8ce19369c65496ea8fa3b00fef16f2e22fd335b1ebb5846bd57"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-openmp-2024.0.0-intel_49819.tar.bz2",
            "feee49a26abc74ef0b57cfb6f521b427d6a93e7d8293d30e941b70d5fd0ab2d9"
        ),


        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-2024.0.0-intel_49656.tar.bz2",
            "e02ad8cf2b0d1c18c4c0a6a06cb23ec6dc076678ab1e5bbc55876aa56f390458"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-2024.0.0-intel_49656.tar.bz2",
            "f6c37ade3153a0a98cf1f50346af32be1b87c4c3cb09e4f7b94dcb77b4896bd7"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-dpcpp-2024.0.0-intel_49656.tar.bz2",
            "ba52047546ced5a6b2060dd6c59384af1ab9aefaa47fdc202fbbde2d07602658"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-dpcpp-2024.0.0-intel_49656.tar.bz2",
            "90065d0dc77d5b61383418aba7f2162e89159d75da5ae2af01bccfcc406010c4"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-include-2024.0.0-intel_49656.tar.bz2",
            "fcbdf5d4197f18fb91fa1d9648f35a45628cc1131ff58c83dcbafe2767490571"
        ),

        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-blas-2024.0.0-intel_49656.tar.bz2",
            "fb8e20ed64ba32602173a70ef1006bec8efd3baad5e5acee79a4bdad3372ba53"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-lapack-2024.0.0-intel_49656.tar.bz2",
            "64908222e5b2d8f0859741bb0c1a9be57f452f284a271d9540fd8e44a814c0aa"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-sparse-2024.0.0-intel_49656.tar.bz2",
            "43398954718cfcc82798126716f3b8c6d300c54f2fbf7502eccfef218ed01165"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-datafitting-2024.0.0-intel_49656.tar.bz2",
            "1383e8f10540d1a6cb892841d44503e765041c730562b32be7b61cff570bab3e"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-dft-2024.0.0-intel_49656.tar.bz2",
            "2f881c965a9cecbdcc0a0361b7f1c5d07d580cc7a1fe8e9a7f461d6134006623"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-rng-2024.0.0-intel_49656.tar.bz2",
            "7bd159c258184a4c74dae84e666538d233b6bfedc1c6413a0c9cfcc42934c194"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-stats-2024.0.0-intel_49656.tar.bz2",
            "5ee1eb1fde278e5e98bc58c53137602c3c939a9a593cd7729c15440ee3196ece"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-vm-2024.0.0-intel_49656.tar.bz2",
            "2d65f55ddc91d334abfb8e119303046e22d5b7070ad522a3d8a8681b1bd9cf26"
        ),
    ],
    Platform("x86_64", "windows") => [
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/dpcpp-cpp-rt-2024.0.0-intel_49840.tar.bz2",
            "f39e13f4ead6d374db5b10a0b73a063a43146890cb66677d49c65c9c9d4fea15"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/dpcpp_impl_win-64-2024.0.0-intel_49840.tar.bz2",
            "b00cbbfdea2573d9d18acf5decf14ab5a84cd9a95debe98138679e36eafbae18"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/dpcpp_win-64-2024.0.0-intel_49840.tar.bz2",
            "25e3f412dd0640c7fb4345737b040cc74abf24c2d84a733e1e16c849d476ceef"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/icc_rt-2024.0.0-intel_49840.tar.bz2",
            "6b54706c8e7125f5d4b57cc280012e6c5bf4af1dd66fcc2e539fbcde12d0ef3d"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/intel-cmplr-lib-rt-2024.0.0-intel_49840.tar.bz2",
            "3b811802fa415f930c8b75e73fd7d3c480f972d1a20111924beb820ecace7e2f"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/intel-cmplr-lic-rt-2024.0.0-intel_49840.tar.bz2",
            "1a1e1230e0fe6caa53c176c360c7802bc32327d06efc7e6273881e525dd9d275"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/intel-opencl-rt-2024.0.0-intel_49840.tar.bz2",
            "ef41d535608851985a0ba14e3e750c4545c60d0de2e61ab97610f49fd653691a"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/intel-openmp-2024.0.0-intel_49840.tar.bz2",
            "a971532e9a397ec2907d079183f2852d907e42b8ac7616e53e1d3dd664903721"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/mkl-2024.0.0-intel_49657.tar.bz2",
            "5e69fd6314f5ed95da076bdf1a4701aa234dc842d5dfc845d5b2e05e12cd7fcc"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/mkl-devel-2024.0.0-intel_49657.tar.bz2",
            "05e43480b2bf0a4f6e6f3208aa88e613b0b44e6639c7c5e52bef518193364dba"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/mkl-devel-dpcpp-2024.0.0-intel_49657.tar.bz2",
            "2b6e79c087e2d2931cc77a74865f843fe7c010205161516e6bf199d956328e5f"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/mkl-dpcpp-2024.0.0-intel_49657.tar.bz2",
            "cf26dca28599894e46b7654926a28ac4736c8f2d588a824ef650a9f3d985d869"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/mkl-include-2024.0.0-intel_49657.tar.bz2",
            "8f4215100f4360017721ce154c0fd9fa1628c78ac733e4cbd863d1bf3ab4f21d"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/onemkl-sycl-blas-2024.0.0-intel_49657.tar.bz2",
            "701c1880f1af2ac1a98f2f068ec627dee6c46a4e5bcc4df6676a7e516b3aa7e2"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/onemkl-sycl-lapack-2024.0.0-intel_49657.tar.bz2",
            "a9b55c841a25ed0f150d5c7ad3594af24d5fce78334cb4d64cbe87b9380e2885"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/onemkl-sycl-sparse-2024.0.0-intel_49657.tar.bz2",
            "3b6e3d0ec5ab110107e1c490c6c157db848d113738d5cd9791bf4cd525de749c"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/onemkl-sycl-datafitting-2024.0.0-intel_49657.tar.bz2",
            "76d412c83da3d1ecb7376a270832b403197410b19ddbb0ed56f1609d10168599"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/onemkl-sycl-dft-2024.0.0-intel_49657.tar.bz2",
            "06b4d47361f3de27743e9901bbf3ebbcfec5e40ca5f9e2f5700027c7f55550c3"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/onemkl-sycl-rng-2024.0.0-intel_49657.tar.bz2",
            "2157848543705f83ae2dbf93b7d464a2cc342fe58665ce20512adb5a6f721c24"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/onemkl-sycl-stats-2024.0.0-intel_49657.tar.bz2",
            "d6458f559507c128632caf9fffd49c0ae7fa33951041608267e75bbb488387d3"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/win-64/onemkl-sycl-vm-2024.0.0-intel_49657.tar.bz2",
            "85ef20d4abf901475770e52f5cccc690e04673b61d25b1e9a739e35e68218df5"
        )
    ]
)

script = raw"""
install_license "info/licenses/license.txt"
mkdir -p ${libdir} ${includedir}

# some Windows packages put stuff in a Library/ directory
if [[ "${target}" == *-mingw* ]]; then
    rsync --archive --remove-source-files Library/ .
    rm -rf Library
fi

# install dependencies in the prefix
# NOTE: these dependencies _should_ be packaged as JLLs we can depend on,
#       but that's just a lot of work and not worth it for this single build
cp -r include/* ${includedir}
mv lib/clang/*/include/CL ${includedir}
rm -rf lib/clang
for lib in sycl OpenCL svml irng imf intlc pi_level_zero pi_opencl \
        mkl_core mkl_intel_ilp64 mkl_sequential mkl_sycl; do
    if [[ "${target}" == *-mingw* ]]; then
        cp -a bin/${lib}*.dll ${libdir} || true
        cp -a lib/${lib}*.lib ${libdir} || true
    else
        cp -a lib/lib${lib}*.so* ${libdir}
    fi
done

cd $WORKSPACE/srcdir/oneAPI.jl/deps

# hacks for Windows
if [[ "${target}" == *-mingw* ]]; then
    ## shared libraries are named differently
    sed -i 's/ sycl/ sycl7/' CMakeLists.txt
    sed -i 's/ mkl_intel_ilp64/ mkl_intel_ilp64_dll/' CMakeLists.txt
    sed -i 's/ mkl_core/ mkl_core.2/' CMakeLists.txt
    sed -i 's/ mkl_sequential/ mkl_sequential.2/' CMakeLists.txt

    ## not sure why we rely on these?
    cp $(realpath $prefix/lib/gcc/x86_64-w64-mingw32/13/libmsvcrt.a) $prefix/bin/libMSVCRT.a
    touch empty.c
    gcc -c empty.c -o empty.o
    ar rcs $prefix/bin/libOLDNAMES.a empty.o
fi

CMAKE_FLAGS=()
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=RelWithDebInfo)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
# XXX: we use the Clang version to work around an issue with the SYCL headers
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
# XXX: why is this needed? broken toolchain file?
CMAKE_FLAGS+=(-DCMAKE_SHARED_LINKER_FLAGS="-L${libdir}")
CMAKE_FLAGS+=(-DCMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES="$prefix/include")
cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}

ninja -C build -j ${nproc} install

# remove build-time dependencies we don't need
rm -rf ${includedir}
rm -f  ${libdir}/*.lib ${libdir}/*.a
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["liboneapi_support"], :liboneapi_support),
]

# Platforms that we will build for
platforms = collect(keys(platform_sources))
filter!(platforms) do platform
    should_build_platform(triplet(platform))
end

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("oneAPI_Level_Zero_Headers_jll"),
    BuildDependency("CompilerSupportLibraries_jll"),
    Dependency("oneAPI_Level_Zero_Loader_jll"; platforms=filter(!Sys.iswindows, platforms))
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
for (idx, platform) in enumerate(platforms)
    # Use "--register" only on the last invocation of build_tarballs
    if idx < length(platforms)
        args = non_reg_ARGS
    else
        args = ARGS
    end

    sources = [generic_sources; platform_sources[platform]]
    build_tarballs(args, name, version, sources, script, [platform],
                   products, dependencies; preferred_gcc_version=v"8")
end
