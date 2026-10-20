# Rebuild std for i686-pc-windows-gnu with panic=abort.
#
# Our i686-w64-mingw32 GCC uses SJLJ exceptions, which Rust does not support.
# BinaryBuilderBase forces `-C panic=abort` on this platform, so nothing
# unwinds, but the prebuilt `libstd` still calls `_Unwind_Resume` from its
# landing pads and personality routine, and the SJLJ libgcc does not define
# it. So we rebuild std with panic=abort, with the personality routine and
# the startup `.eh_frame` registration patched out (see bundled/patches).
#
# We use rust-lang/rust's own build system in local-rebuild mode (the rustup
# toolchain of the same version is the stage0 compiler) and take its
# `rust-std` dist tarball, so the result matches the prebuilt component in
# layout and codegen settings. It is a cross build because the raw-dylib
# imports in std need the mingw `dlltool`.

const abort_std_platform = Platform("i686", "windows")

const abort_std_script = raw"""
cd ${WORKSPACE}/srcdir
export CARGO_HOME=${WORKSPACE}/rust RUSTUP_HOME=${WORKSPACE}/rust
chmod +x rustup-init
./rustup-init -y --no-modify-path --profile minimal --default-host=${rust_host} --default-toolchain ${version}

cd rustc-${version}-src
for p in ${WORKSPACE}/srcdir/patches/*.patch; do atomic_patch -p1 ${p}; done
cp ${WORKSPACE}/srcdir/bootstrap.toml .
export RUSTFLAGS_BOOTSTRAP="-C panic=abort" RUSTFLAGS_NOT_BOOTSTRAP="-C panic=abort"
# bootstrap remaps Rust paths itself; this does the same for the compiler-rt C objects
export CFLAGS_$(echo ${rust_target} | tr - _)="-fdebug-prefix-map=${PWD}=/rustc/${commit}"
# Host build scripts must not link with the target `cc`
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER=x86_64-linux-musl-gcc
python3 x.py dist rust-std --stage 0 --host ${rust_host} --target ${rust_target}

tar -C ${WORKSPACE} -xzf build/dist/rust-std-${version}-${rust_target}.tar.gz
mkdir -p ${prefix}/lib/rustlib
cp -r ${WORKSPACE}/rust-std-${version}-${rust_target}/rust-std-${rust_target}/lib/rustlib/${rust_target} ${prefix}/lib/rustlib/
"""

# Returns the path of the rebuilt `lib/rustlib/i686-pc-windows-gnu` tree
function build_abort_std(ARGS, version, commit, rustup_source)
    sources = [
        rustup_source,
        ArchiveSource("https://static.rust-lang.org/dist/rustc-$(version)-src.tar.xz",
                      "de002ee301c1b7422b0a7b09d7c4cb4924cd3224e6cfb24f065dad786dd3ed12"),
        DirectorySource("./bundled"),
    ]
    script = "version=$(version)\ncommit=$(commit)\n" * abort_std_script
    # GCC 12 matches the shard whose crt2.o build_tarballs.jl copies in
    build_info = build_tarballs(ARGS, "RustAbortStd", version, sources, script, [abort_std_platform], Product[], Dependency[];
                                skip_audit=true, preferred_gcc_version=v"12")
    # We don't actually need the .tar.gz it creates, so delete that to save space
    rm(joinpath("products", first(values(build_info))[1]))
    return joinpath(artifact_path(first(values(build_info))[3]), "lib", "rustlib", map_rust_target(abort_std_platform))
end
