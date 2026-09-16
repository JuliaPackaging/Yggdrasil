# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Lavapipe"
version = v"26.2.2"

# Lavapipe is Mesa's software Vulkan driver: the `swrast` Vulkan driver, i.e. the Vulkan
# frontend of the llvmpipe gallium driver, which JITs shaders with LLVM. Mesa's meson
# enforces that ("Lavapipe Vulkan driver requires LLVM"), so unlike Mesa_jll -- which is a
# deliberately LLVM-free softpipe build for soft OpenGL -- this recipe needs LLVM.
#
# LLVM is linked *statically* and nothing of it is shipped. That matters beyond size: the
# ICD is dlopened into a process that already has Julia's own libLLVM mapped. Mesa builds
# the driver with `gnu_symbol_visibility: 'hidden'`, `-Bsymbolic` and a version script that
# exports only the `vk_icd*` entry points (src/gallium/targets/lavapipe/meson.build), so
# the two LLVMs cannot see each other.
llvm_version = v"22.1.1"
macos_sdk_version = "11.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://archive.mesa3d.org/mesa-$(version).tar.xz",
                  "eeb29ca7e56cfaa8e8a79538dcf834e3b18e501c31bef5145e959ea437cc4216"),
    # Lavapipe's ray-tracing acceleration structures are built by GLSL shaders that Mesa
    # compiles during the build (`with_bvh` in meson.build) with a glslangValidator running
    # on the *build* machine. Mesa requires >= 12.2 and glslang_jll is still 11.7.0, so
    # build one for the host; once glslang_jll is bumped this can be a HostBuildDependency.
    # 15.0.0 is the last tag whose cmake_minimum_required (3.17.2) the rootfs' CMake
    # 3.21.7 satisfies; 15.1+ wants 3.27.
    GitSource("https://github.com/KhronosGroup/glslang.git",
              "46ef757e048e760b46601e6e77ae0cb72c97bd2f"), # tag 15.0.0
    # Mesa only accepts an interpreter that has mako, packaging and yaml (meson.build's
    # python_exec_list loop), and the rootfs' py3-* packages belong to its Python 3.9,
    # which Mesa no longer accepts at all. Carry the sdists and put them on the newer
    # interpreter's path; all four are pure Python (PyYAML's C extension is optional).
    ArchiveSource("https://files.pythonhosted.org/packages/2a/12/b5fa2353e2754cd67fb9f83793fa48ff42c213a5da7e719869d2301f6ab8/mako-1.4.1.tar.gz",
                  "d7904710b662996425a21627710c4777c45053146942cf8a7aebf757c92b8c27"),
    ArchiveSource("https://files.pythonhosted.org/packages/7e/99/7690b6d4034fffd95959cbe0c02de8deb3098cc577c67bb6a24fe5d7caa7/markupsafe-3.0.3.tar.gz",
                  "722695808f4b6457b320fdc131280796bdceb04ab50fe1795cd540799ebe1698"),
    ArchiveSource("https://files.pythonhosted.org/packages/7d/fa/3944b40b07da9ce895c0e6303a5ab7d53da063554f534556b134a54d6093/packaging-26.3.tar.gz",
                  "94edc256424af38762eb31306eed28beb9f0efc50a8837492c9d6fd6004aed79"),
    ArchiveSource("https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz",
                  "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"),
    # Mesa's Win32 WSI includes <directx/d3d12.h> unconditionally, and there is no
    # DirectX_Headers_jll to depend on. Headers only, MIT, tiny to build.
    GitSource("https://github.com/microsoft/DirectX-Headers.git",
              "ee479f0bd5f7b884f202bcf0c3f076cc050dd256"), # tag v1.619.5
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# Mesa >= 26.1 requires Python >= 3.10 while the rootfs ships 3.9, so hand it the
# interpreter from Python_jll, wrapped. Both exports have to stay inside the wrapper:
# LD_LIBRARY_PATH because its pyexpat needs that Python's own libexpat rather than the
# rootfs' older one, and PYTHONPATH because meson walks python_exec_list and takes the first
# interpreter that can import mako and yaml -- set it globally and meson picks the bare
# python3.12 next to the wrapper, which then cannot load pyexpat.
mkdir -p ${WORKSPACE}/srcdir/pybin
cat > ${WORKSPACE}/srcdir/pybin/python3 <<EOF
#!/bin/bash
export LD_LIBRARY_PATH=${host_prefix}/lib:\${LD_LIBRARY_PATH}
export PYTHONPATH=$(echo ${WORKSPACE}/srcdir/mako-*):$(echo ${WORKSPACE}/srcdir/markupsafe-*/src):$(echo ${WORKSPACE}/srcdir/packaging-*/src):$(echo ${WORKSPACE}/srcdir/pyyaml-*/lib)
exec ${host_prefix}/bin/python3 "\$@"
EOF
chmod +x ${WORKSPACE}/srcdir/pybin/python3
# The runner appends host_bindir *after* /usr/bin, so put ours in front explicitly.
export PATH=${WORKSPACE}/srcdir/pybin:${PATH}
python3 --version
python3 -c "import mako, yaml; from packaging.version import Version; print('mako', mako.__version__)"

# glslangValidator for the build machine, used by Mesa to compile the BVH shaders. The
# SPIR-V optimizer is off because Mesa invokes glslang without it (`-V --target-env
# spirv1.5`, src/vulkan/runtime/bvh/meson.build) and enabling it would drag in SPIRV-Tools.
cmake -B ${WORKSPACE}/srcdir/glslang/build -S ${WORKSPACE}/srcdir/glslang -GNinja \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${host_prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_OPT=OFF \
    -DBUILD_EXTERNAL=OFF \
    -DGLSLANG_TESTS=OFF \
    -DENABLE_HLSL=OFF \
    -DENABLE_SPVREMAPPER=OFF
ninja -C ${WORKSPACE}/srcdir/glslang/build -j${nproc} install
glslangValidator --version

if [[ "${target}" == *-mingw* ]]; then
    # Mesa's Win32 WSI includes <directx/d3d12.h> even with d3d12 itself off. Install the
    # headers outside ${prefix} -- they are a build-time dependency and have no business in
    # the shipped artifact -- and let pkg-config point Mesa at them.
    dxheaders=${WORKSPACE}/srcdir/dxheaders
    meson setup ${WORKSPACE}/srcdir/DirectX-Headers/build ${WORKSPACE}/srcdir/DirectX-Headers \
        --cross-file="${MESON_TARGET_TOOLCHAIN}" \
        --prefix=${dxheaders} \
        -D build-test=false
    ninja -C ${WORKSPACE}/srcdir/DirectX-Headers/build -j${nproc} install
    export PKG_CONFIG_PATH=${dxheaders}/lib/pkgconfig:${PKG_CONFIG_PATH}
fi

cd ${WORKSPACE}/srcdir/mesa-*

for patch in ${WORKSPACE}/srcdir/patches/000[1-4]-*.patch; do
    atomic_patch -p1 ${patch}
done

# Mesa locates LLVM with `llvm-config`. The target LLVM_full_jll ships one, but it is not
# executable here, so use the HostBuildDependency's binary and rewrite what it reports to
# the target prefix. bundled/llvm-config is a verbatim copy of the pocl recipe's shim.
chmod +x ${WORKSPACE}/srcdir/llvm-config
cat > ${WORKSPACE}/srcdir/llvm.ini <<EOF
[binaries]
llvm-config = '${WORKSPACE}/srcdir/llvm-config'
EOF

EXTRA_CROSS_FILES=()
if [[ "${target}" == *-apple-* ]]; then
    # Meson probes the linker with `-Wl,--version`; Apple's ld rejects that, so meson falls
    # into its Apple branch -- which re-runs `clang -Wl,-v` *without* the `-fuse-ld` from
    # the toolchain file (mesonbuild/linkers/detect.py), inspects clang's default linker
    # (lld, which prints no `PROJECT:ld` banner) and gives up with "Unable to detect
    # linker". That second probe does keep the link args, so put -fuse-ld there as well.
    # `-Wl,-x` takes the place of `-D strip=true` below: the linker ad-hoc signs the dylib
    # (mandatory on Apple Silicon) and cctools strip then refuses to touch it, so drop the
    # local symbols while linking, before the signature is computed.

    # ld64 has no version scripts, so 0005 points it at an export list instead. Derive the
    # list from the same vulkan.sym the ELF targets use, so the two cannot drift.
    awk '/vk_icd/ { gsub(/[;[:space:]]/, ""); print "_" $0 }' src/vulkan/vulkan.sym \
        > src/gallium/targets/lavapipe/lvp_exports.sym
    if [[ $(wc -l < src/gallium/targets/lavapipe/lvp_exports.sym) -ne 3 ]]; then
        echo "expected three vk_icd entry points in src/vulkan/vulkan.sym" >&2
        exit 1
    fi
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0005-*.patch

    python3 - "${MESON_TARGET_TOOLCHAIN}" > ${WORKSPACE}/srcdir/darwin-ld.ini <<'PYTHON'
import re, sys

toolchain = open(sys.argv[1]).read()
ld = re.search(r"^c_ld = '([^']+)'", toolchain, re.M).group(1)
added = ["-fuse-ld=" + ld, "-Wl,-x"]
print("[built-in options]")
for key in ("c_link_args", "cpp_link_args", "objc_link_args"):
    match = re.search(r"^" + key + r" = \[(.*)\]$", toolchain, re.M)
    if match is None:
        continue
    args = match.group(1).strip()
    extra = ", ".join("'{}'".format(a) for a in added)
    print("{} = [{}{}]".format(key, args + ", " if args else "", extra))
PYTHON
    cat ${WORKSPACE}/srcdir/darwin-ld.ini
    EXTRA_CROSS_FILES+=(--cross-file="${WORKSPACE}/srcdir/darwin-ld.ini")
fi

MESA_FLAGS=(
    -D b_ndebug=true
    -D buildtype=release
    -D strip=$([[ "${target}" == *-apple-* ]] && echo false || echo true)

    -D gallium-drivers=llvmpipe
    -D vulkan-drivers=swrast
    -D llvm=enabled
    -D shared-llvm=disabled
    # LLVM_full_jll is built without LLVM_ENABLE_RTTI, so Mesa's C++ has to match.
    -D cpp_rtti=false
    # Leave the JIT at Mesa's default, MCJIT, on every cpu family we build for. Its ORCJIT
    # path dynamic_casts an llvm::orc::SimpleCompiler (lp_bld_init_orc.cpp), so it needs an
    # RTTI-enabled LLVM, which LLVM_full_jll is not.

    # Build the Vulkan ICD and nothing else: no GL frontend, no GLX/EGL/GBM.
    -D opengl=false
    -D gles1=disabled
    -D gles2=disabled
    -D glx=disabled
    -D egl=disabled
    -D gbm=disabled
    -D xmlconfig=disabled
    -D spirv-tools=disabled
    -D gallium-va=disabled
    -D video-codecs=[]
)

# Window-system integration. Without it Mesa builds a headless-only ICD, and then the
# Vulkan loader does not advertise VK_KHR_surface at all (it only offers its own
# VK_EXT_headless_surface), which is enough to make ordinary Vulkan applications fail at
# vkCreateInstance. So give every platform the WSI that Mesa supports there.
if [[ "${target}" == *-mingw* ]]; then
    MESA_FLAGS+=(-D platforms=windows)
elif [[ "${target}" == *-apple-* ]]; then
    # Mesa has no macOS WSI; offscreen rendering and VK_EXT_headless_surface only.
    MESA_FLAGS+=(-D platforms=[])
else
    MESA_FLAGS+=(-D platforms=x11)
fi

# --wrap-mode=nodownload: Mesa ships .wrap files (expat among them) and meson would
# happily fetch and vendor an unpinned copy instead of using our dependencies.
meson setup build "${MESA_FLAGS[@]}" \
    --wrap-mode=nodownload \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --cross-file="${WORKSPACE}/srcdir/llvm.ini" \
    "${EXTRA_CROSS_FILES[@]}"
ninja -C build -j${nproc}
ninja -C build install

# The generated ICD manifest hardcodes the build-time library path. The Vulkan loader
# resolves a *relative* `library_path` against the directory of the manifest itself, which
# is what makes an artifact relocatable. Also give the manifest a fixed, arch-independent
# name so the FileProduct path is the same everywhere.
icd_dir=${prefix}/share/vulkan/icd.d
mv ${icd_dir}/lvp_icd.*.json ${icd_dir}/lvp_icd.json
if [[ "${target}" == *-mingw* ]]; then
    lib_path=../../../bin/vulkan_lvp.dll
else
    lib_path=../../../lib/libvulkan_lvp.${dlext}
fi
python3 - ${icd_dir}/lvp_icd.json ${lib_path} <<'PYTHON'
import json, sys
manifest, lib = sys.argv[1], sys.argv[2]
with open(manifest) as f:
    icd = json.load(f)
icd["ICD"]["library_path"] = lib
with open(manifest, "w") as f:
    json.dump(icd, f, indent=4)
PYTHON
cat ${icd_dir}/lvp_icd.json

install_license docs/license.rst
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# LLVM 15+ is not built for i686-linux-musl
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
# 32-bit Windows can't link the static LLVM archives into a PE image
filter!(p -> !(arch(p) == "i686" && Sys.iswindows(p)), platforms)
# Mesa forces ORCJIT wherever LLVM's MCJIT has no port -- `llvm_has_mcjit` in meson.build is
# an exhaustive list of aarch64, arm, ppc, ppc64, s390x, x86 and x86_64 -- and the
# `llvm-orcjit` option can only turn it on, never off. gallivm's ORCJIT path dynamic_casts
# (lp_bld_init_orc.cpp), which -fno-rtti rejects outright, and -fno-rtti is not optional:
# LLVM_full_jll is built without RTTI. So llvmpipe cannot be built for riscv64 at all until
# that JLL gains LLVM_ENABLE_RTTI.
filter!(p -> arch(p) != "riscv64", platforms)
# libdrm_jll's FreeBSD artifacts ship no libdrm.pc -- only pciaccess.pc and zlib.pc -- so
# meson's dependency('libdrm') fails, and Mesa asks for libdrm as soon as any Vulkan driver
# is enabled. Nothing to fix on this side; it needs that JLL rebuilt.
filter!(p -> !Sys.isfreebsd(p), platforms)
platforms = expand_cxxstring_abis(platforms)

# x86_64-apple-darwin only (the ARM builder already defaults to 11.1): the default Intel
# deployment target is 10.12, and libc++ marks std::optional::value() unavailable before
# 10.14, which LLVM 22's headers use.
sources, script = require_macos_sdk(macos_sdk_version, sources, script)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libvulkan_lvp", "vulkan_lvp"], :libvulkan_lvp),
    FileProduct("share/vulkan/icd.d/lvp_icd.json", :lvp_icd),
]

# Register the driver with the Vulkan loader. There is no loader-side driver list to push to
# the way the OpenCL driver JLLs use `OpenCL_jll.drivers`, so this goes through the loader's
# own discovery mechanism: VK_ADD_DRIVER_FILES *adds* to the drivers it finds, unlike
# VK_DRIVER_FILES, so a real GPU stays enumerable alongside this one. The loader reads it at
# vkCreateInstance, so setting it in __init__ is early enough.
init_block = raw"""
let sep = Sys.iswindows() ? ';' : ':',
    found = split(get(ENV, "VK_ADD_DRIVER_FILES", ""), sep; keepempty=false)
    if !(lvp_icd in found)
        ENV["VK_ADD_DRIVER_FILES"] = join(vcat(found, lvp_icd), sep)
    end
end
"""

# Dependencies that must be installed before this package can be built
dependencies = [
    # LLVM twice: the target build to link against, and the host build for an executable
    # `llvm-config` whose output the shim rewrites to the target prefix.
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    HostBuildDependency("Python_jll"),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("Zstd_jll"; compat="1.5.7"), # the LLVM 22 build has LLVM_ENABLE_ZSTD=ON
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
]

# Where the DRI platform is DRM, Mesa's Vulkan runtime wants libdrm as soon as any Vulkan
# driver is enabled (`with_dri2`), even though lavapipe never touches a GPU; the X11 WSI
# adds the xcb stack on top. macOS and Windows use neither.
x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)
append!(dependencies, [
    Dependency("libdrm_jll"; compat="2.4.134", platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; compat="1.8.12", platforms=x11_platforms),
    Dependency("Xorg_libxcb_jll"; compat="1.17.1", platforms=x11_platforms),
    Dependency("Xorg_libxshmfence_jll"; compat="1.3.3", platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; compat="1.3.8", platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; compat="1.5.6", platforms=x11_platforms),
    Dependency("Xorg_xorgproto_jll"; compat="2024.1.1", platforms=x11_platforms),
])

# Windows needs binutils >= 2.45, i.e. GCC 15: older `ld` emits a 32-bit HIGHLOW base
# relocation for the SECREL32 fixup of a thread_local in a `.tls$<name>` comdat section --
# how clang, and so LLVM_full_jll, lays out LLVM's thread_locals. It lands in the
# displacement of the instruction reading the variable, so any load away from the preferred
# base corrupts it and the first thread_local read faults inside vkCreateDevice.
# x86_64-apple-darwin cannot have GCC 15: that shard's ld64 needs a libdispatch.so that
# ships in no shard. Hence two builds over disjoint platform sets.
windows_platforms = filter(Sys.iswindows, platforms)
other_platforms = setdiff(platforms, windows_platforms)

if any(should_build_platform.(triplet.(windows_platforms)))
    build_tarballs(ARGS, name, version, sources, script, windows_platforms, products, dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"15", init_block)
end
if any(should_build_platform.(triplet.(other_platforms)))
    build_tarballs(ARGS, name, version, sources, script, other_platforms, products, dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"12", init_block)
end
