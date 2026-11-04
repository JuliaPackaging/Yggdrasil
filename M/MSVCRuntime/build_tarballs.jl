using BinaryBuilder, Pkg

# The Microsoft Visual C++ runtime (msvcp140.dll, vcruntime140.dll, ...), for MSVC-built
# binaries that we repackage on Windows. Microsoft allows redistributing these DLLs with an
# application; we take them from conda-forge's vc14_runtime package, which repackages them
# from the Visual Studio redistributable. The Universal CRT (api-ms-win-crt-*) is part of
# Windows 10 and later, so it is not included.
name = "MSVCRuntime"
version = v"14.51.36247"

sources = [
    # https://anaconda.org/conda-forge/vc14_runtime/files
    FileSource("https://conda.anaconda.org/conda-forge/win-64/vc14_runtime-14.51.36247-habf1de7_41.conda",
               "4e4cb599cdc41bf2109d1464c127b5bcbddf548ce3e322e612afb691338b48f8"; filename="vc14_runtime.conda"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
apk add zstd
unzip -q vc14_runtime.conda
mkdir pkg info
tar --use-compress-program=unzstd -xf pkg-*.tar.zst -C pkg
tar --use-compress-program=unzstd -xf info-*.tar.zst -C info

install -Dvm 755 pkg/Library/bin/*.dll -t ${libdir}
install_license info/info/licenses/LICENSE.TXT
"""

platforms = [
    Platform("x86_64", "windows"),
]

# Loaded by the init block below instead of eagerly.
products = [
    LibraryProduct("vcruntime140", :vcruntime140; dont_dlopen=true),
    LibraryProduct("vcruntime140_1", :vcruntime140_1; dont_dlopen=true),
    LibraryProduct("msvcp140", :msvcp140; dont_dlopen=true),
]

dependencies = Dependency[]

# Windows resolves a DLL import against an already-loaded module of the same name, so
# whichever copy is loaded first serves the whole process. The runtime is backward
# compatible (binaries built with an older toolset run on a newer runtime, not vice versa),
# so we load our copies, which track the latest release, rather than whatever older
# version may be installed system-wide or found on PATH. If the process already loaded
# the runtime, we leave it alone: loading a second copy would not change what is used.
init_block = raw"""
    for (name, path) in (("vcruntime140.dll", vcruntime140_path),
                         ("vcruntime140_1.dll", vcruntime140_1_path),
                         ("msvcp140.dll", msvcp140_path))
        if ccall((:GetModuleHandleW, "kernel32"), stdcall, Ptr{Cvoid}, (Cwstring,), name) == C_NULL
            Libdl.dlopen(path)
        end
    end
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", init_block)
