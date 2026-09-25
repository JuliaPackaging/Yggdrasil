using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

# Repackage the ROCm vendor libraries (rocBLAS, rocSPARSE, rocSOLVER, rocRAND,
# rocFFT and MIOpen, together with their private in-bundle dependencies hipBLASLt,
# rocRoller and rocm_kpack) from AMD's TheRock tarballs. All the compiler/llvm stuff
# we build ourselves, so we can ship much smaller tarballs by excluding these

# This does platform augmentation with the ROCm arch as well as the ROCm version,
# so we don't have to ship huge tarballs with code for every architecture possible

name = "ROCm_Libs"
version = v"7.14.0"

const rocm_versions = [v"7.14.0"]

# sha256 hashes per (rocm version, rocm_arch tag, os) of the bundles published by
# TheRock; not every bundle is available for every OS
const bundle_hashes = Dict(
    v"7.14.0" => Dict(
        ("gfx908", "linux")         => "1686270efa2e523889168ec6a4343f2e53f173d6026fdb9c6b308d99f99d99fa",
        ("gfx90a", "linux")         => "b1caebb79f542951114ef6478ea587a691d005cc13c2efadfec577bd82b6fc78",
        ("gfx94x_dcgpu", "linux")   => "32e16dca7f8440a08a8d636a6a7db0034c61518f32ea915347b98d9f55199b0c",
        ("gfx950_dcgpu", "linux")   => "12afeccd06e6caf0699d86d688f16083aafa35474d0ec1d8063477fb5c119d49",
        ("gfx101x_dgpu", "linux")   => "fdb302ee45e9e3a6dcb6bab295fdf2e6a4c0f8b2c7a4937698b18178715822d9",
        ("gfx101x_dgpu", "windows") => "58b33f43d67dae68087cff37494c13267a7613eda6202e1ee904097643e5958d",
        ("gfx103x_all", "linux")    => "ce9a5be2b43ee1bdd85de3fa9ea3c3d5dcb6875445acf7281c3763a4ee783f19",
        ("gfx103x_all", "windows")  => "93f5244854cd1bec2ea29bb977e448a2b79c7ee77609d253ab075ea24404462c",
        ("gfx110x_all", "linux")    => "e78a4445c52d879fbd0765f24e7fa9df1e262a8baf681b118a13e75340120127",
        ("gfx110x_all", "windows")  => "3ce5d7fcd56f7b169ba9f95916553b7cd6bb0370d98b1c0ce572eb34874630d6",
        ("gfx1150", "linux")        => "d73f8e29a21d031051466dad88d5dba273582819521f5930d9f100a7e7dd0905",
        ("gfx1150", "windows")      => "5f990ab9a3ca55b39fe771c92877fc950ba7a1702004d27395b2b7bf8a7ec56d",
        ("gfx1151", "linux")        => "2567d5e34e470db104a62a02c36aa770cb0430175e48c1c46df0eefc05e1d77c",
        ("gfx1151", "windows")      => "6d962c8868388e3d81a504c3b58caada49d40fd7a67b52da73319159f1479fe7",
        ("gfx1152", "linux")        => "390c87f4bcacf026578fbfb36267a23912524f023f77f7f9322ecaaf61d88b60",
        ("gfx1152", "windows")      => "2966c84fcb14865e5700603d68267cf037b18cf65b862e642553f3a882ab4bee",
        ("gfx1153", "linux")        => "56dc233ace740364dca06ca12c22749a85e5f5f54ae3812ca24426d3c5eb787d",
        ("gfx1153", "windows")      => "465070a1004cbd6c6762f5e43ba96a5ce8c1a83a7c0fa6c4aad2d8563d82fc28",
        ("gfx120x_all", "linux")    => "2a304d07b925c7e46e51fa8f719b195a9bfe2df2cc920d706f10a29d2d2471af",
        ("gfx120x_all", "windows")  => "87091e92ff9fcc0a590193b9d42bd48cf8e9ce9df258efeb52de7d3c3e44d395",
    ),
)

augment_platform_block = """
    const ROCm_Libs_jll_uuid = Base.UUID("07d9647d-253f-508d-88af-3defef7976bb")
    const rocm_toolkits = $(repr(rocm_versions))
    $(read(joinpath(@__DIR__, "platform_augmentation.jl"), String))"""

script = raw"""
cd ${WORKSPACE}/srcdir

# Windows bundles wrap everything in a top-level directory, Linux doesn't
if compgen -G "therock-dist-*" > /dev/null; then
    cd therock-dist-*
fi

# rename licenses
mkdir -p ${WORKSPACE}/licenses
for doc in rocblas hipblaslt rocroller rocsparse rocsolver rocrand rocfft miopen-hip; do
    if [[ -f share/doc/${doc}/LICENSE.md ]]; then
        cp share/doc/${doc}/LICENSE.md ${WORKSPACE}/licenses/LICENSE.${doc}.md
    fi
done
install_license ${WORKSPACE}/licenses/*

if [[ ${target} == *-linux-gnu ]]; then
    mkdir -p ${libdir}

    # the vendor libraries themselves (preserving SONAME symlinks)
    mv lib/librocblas.so* lib/librocsparse.so* lib/librocsolver.so* \
       lib/librocrand.so* lib/librocfft.so* lib/libMIOpen.so* ${libdir}

    # private in-bundle dependencies: rocblas links hipblaslt, which links rocroller;
    # rocm_kpack is used to load the kernel packs below
    mv lib/libhipblaslt.so* ${libdir}
    mv lib/librocroller.so* ${libdir} || true
    mv lib/librocm_kpack.so* ${libdir} || true

    # MIOpen's composable-kernel plugin(s), dlopened at runtime
    mv lib/libMIOpenCKGroupedConv_*.so ${libdir} || true

    # the small rocm_sysdeps libraries the above link against, resolved through their
    # `$ORIGIN/rocm_sysdeps/lib` RUNPATH entry
    mkdir -p ${libdir}/rocm_sysdeps/lib
    for dep in zstd bz2 sqlite3 z; do
        mv lib/rocm_sysdeps/lib/librocm_sysdeps_${dep}.so* ${libdir}/rocm_sysdeps/lib || true
    done

    # device code and auxiliary data, located relative to the libraries
    mkdir -p ${libdir}/rocblas ${libdir}/hipblaslt
    mv lib/rocblas/library ${libdir}/rocblas/
    mv lib/hipblaslt/library ${libdir}/hipblaslt/ || true
    mv lib/rocfft ${libdir}/  # also contains the rocfft_rtc_helper executable
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    mkdir -p ${bindir}

    mv bin/rocblas.dll bin/rocsparse.dll bin/rocsolver.dll \
       bin/rocrand.dll bin/rocfft.dll bin/MIOpen.dll ${bindir}

    mv bin/libhipblaslt.dll ${bindir}
    mv bin/rocm_kpack.dll ${bindir} || true
    mv bin/MIOpenCKGroupedConv_*.dll ${bindir} || true
    mv bin/rocfft_rtc_helper.exe ${bindir} || true

    mkdir -p ${bindir}/rocblas ${bindir}/hipblaslt
    mv bin/rocblas/library ${bindir}/rocblas/
    mv bin/hipblaslt/library ${bindir}/hipblaslt/ || true

    find ${bindir} -maxdepth 1 \( -name '*.dll' -o -name '*.exe' \) -exec chmod +x {} +
fi

# kernel packs for the shipped libraries, loaded through rocm_kpack
mkdir -p ${prefix}/.kpack
mv .kpack/blas_lib_*.kpack .kpack/fft_lib_*.kpack .kpack/rand_lib_*.kpack ${prefix}/.kpack/ || true
"""

products = [
    LibraryProduct(["librocblas", "rocblas"], :librocblas),
    LibraryProduct(["librocsparse", "rocsparse"], :librocsparse),
    LibraryProduct(["librocsolver", "rocsolver"], :librocsolver),
    LibraryProduct(["librocrand", "rocrand"], :librocrand),
    LibraryProduct(["librocfft", "rocfft"], :librocfft),
    LibraryProduct(["libMIOpen", "MIOpen"], :libMIOpen),
    LibraryProduct("libhipblaslt", :libhipblaslt),
]

dependencies = []

# determine exactly which tarballs we should build
builds = []
for rocm_version in rocm_versions
    for ((arch_tag, os), sha256) in sort!(collect(bundle_hashes[rocm_version]))
        # TheRock spells the architecture family with a capital X and dashes in URLs
        url_arch = replace(arch_tag, "x_" => "X-", "_" => "-")
        source = ArchiveSource("https://repo.amd.com/rocm/tarball-multi-arch/therock-dist-$(os)-$(url_arch)-$(rocm_version).tar.gz",
                               sha256)

        platform = if os == "linux"
            Platform("x86_64", "linux"; libc="glibc")
        else
            Platform("x86_64", "windows")
        end
        platform["rocm_arch"] = arch_tag
        platform["rocm"] = "$(rocm_version.major).$(rocm_version.minor)"

        should_build_platform(triplet(platform)) || continue

        push!(builds, (; platforms=[platform], sources=[source]))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, dependencies;
                   julia_compat="1.6", augment_platform_block,
                   lazy_artifacts=true, skip_audit=true, dont_dlopen=true)
end
