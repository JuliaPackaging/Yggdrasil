using BinaryBuilder, Pkg

name = "Rusticl"
version = v"25.2.0"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    GitSource("https://gitlab.freedesktop.org/mesa/mesa",
              "bac51d2931199a1e9048c7acdae155865732ad01"),  # HEAD, before Rusticl required VK_EXT_robustness2
]

# Bash recipe for building across all platforms
script = raw"""
# we need meson 1.7+
#apk add --upgrade meson --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main
# XXX: upgrading via apk doesn't work due to python version mismatches
pip install -U meson

apk add py3-mako py3-yaml

# build bindgen. this is tricky for multiple reasons:
# - it needs to be built for the host platform
# - the host uses musl, which only has a functional dlopen in its dynamic libary
# - convincing cargo to link dynamically against the C runtime results in
#   rust picking up the much older libc that's shipped as part of the gcc shard
## replace the sysroot libc with the one from the rootfs
# XXX: bump the baseline instead
mv /opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/lib/libc.so /opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/lib/libc.so.old
ln -s /lib/libc.musl-x86_64.so.1 /opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/lib/libc.so
## install bindgen
RUSTFLAGS="-C target-feature=-crt-static" \
cargo install bindgen-cli --target $rust_host

cd $WORKSPACE/srcdir/mesa

install_license licenses/MIT

for patch in $WORKSPACE/srcdir/patches/*.patch; do
    atomic_patch -p1 $patch
done

mkdir build && cd build

MESON_FLAGS=()
# Install things into $prefix
MESON_FLAGS+=(-Dprefix=${prefix})
# Explicitly use our Meson toolchain file
MESON_FLAGS+=(--cross-file="${MESON_TARGET_TOOLCHAIN}")
MESON_FLAGS+=(--native-file="${MESON_HOST_TOOLCHAIN}")
# Release build for best performance
MESON_FLAGS+=(--buildtype=release)
# Disable things we don't need
MESON_FLAGS+=(-Dplatforms=)
MESON_FLAGS+=(-Dglx=disabled)
MESON_FLAGS+=(-Dgles1=disabled)
MESON_FLAGS+=(-Dvideo-codecs=)
MESON_FLAGS+=(-Dgallium-va=disabled)
MESON_FLAGS+=(-Dgallium-vdpau=disabled)
MESON_FLAGS+=(-Dvulkan-drivers=)
# Enable Rusticl
MESON_FLAGS+=(-Dgallium-rusticl=true)
MESON_FLAGS+=(-Drust_std=2021)
MESON_FLAGS+=(-Dllvm=disabled)
# TODO: support LLVM
MESON_FLAGS+=(-Drusticl-enable-opencl-c=false)
# Enable Gallium drivers
MESON_FLAGS+=(-Dgallium-drivers=zink)
# Embed libclc
MESON_FLAGS+=(-Dstatic-libclc=all)

# point Meson to the right `rustc` binaries
# XXX: fix this upstream (JuliaPackaging/Yggdrasil#11679)
host=$MACHTYPE
host_rustc=$(echo /opt/bin/${host}*/rustc)
target_rustc=$(echo /opt/bin/${target}*/rustc)
sed -i "/^\[binaries\]/a rust = '$host_rustc'" "${MESON_HOST_TOOLCHAIN}"
sed -i "/^\[binaries\]/a rust = '$target_rustc'" "${MESON_TARGET_TOOLCHAIN}"

# meson doesn't forward the target environment to bindgen
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=/opt/$target/$target/sys-root"

meson .. "${MESON_FLAGS[@]}"

ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux";  libc="glibc"),
]
# TODO: support additional platforms
# - musl: sys/random.h: No such file or directory
# - riscv64: no Rust toolchain
# - armv6 & armv7: invalid `host_rustc`
# - ppc64: gnu/stubs-32.h not found (bindgen)
# - i686-linux: gnu/stubs-64.h not found (bindgen)
# - darwin: Unable to detect linker (ld: unknown option: --version)
# - windows: lol

# The products that we will ensure are always built
products = [
    LibraryProduct("libRusticlOpenCL", :libRusticlOpenCL),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libclc_jll"),
    Dependency("SPIRV_Tools_jll"),
    Dependency("libdrm_jll"),       # XXX: can we get rid of this?
    Dependency("OpenCL_jll"),
]

init_block = raw"""
    # Register this driver with OpenCL_jll
    if OpenCL_jll.is_available()
        push!(OpenCL_jll.drivers, libRusticlOpenCL)
    end
"""

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], preferred_gcc_version=v"8",
               init_block)
