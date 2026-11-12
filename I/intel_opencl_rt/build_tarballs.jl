using BinaryBuilder, Pkg

# Intel's OpenCL runtime for CPUs, an OpenCL ICD driver (libintelocl) that also works on
# non-Intel x86_64 CPUs. Intel does not publish its source, so we repackage the binaries
# from the PyPI wheels, which come with a redistribution license (like MKL and IntelOpenMP).
# Intel only ships x86_64 Linux and Windows builds.
name = "intel_opencl_rt"
version = v"2026.1.2"

sources = [
    # https://pypi.org/project/intel-opencl-rt/#files
    FileSource("https://files.pythonhosted.org/packages/1d/3d/895a1628ca64752a235a045a649609d6e3b3f42b1588312225bf2fd7dd48/intel_opencl_rt-2026.1.2-py2.py3-none-manylinux_2_28_x86_64.whl",
               "b543a09209fc157a70eb40f72338862a35cf86ad1ef4808d4e89cf0078bf8947"; filename="intel_opencl_rt-x86_64-linux-gnu.whl"),
    FileSource("https://files.pythonhosted.org/packages/94/4e/dea179a1beb493fcf5bfc5f4680f5a2660373b8f00be0ce3ec89eeeb3942/intel_opencl_rt-2026.1.2-py2.py3-none-win_amd64.whl",
               "9b4da9a4e12e56c5eda5c93c22a8eb0579f5811d27a5d8cc1171303208308320"; filename="intel_opencl_rt-x86_64-w64-mingw32.whl"),
    # On Linux, libintelocl also links Intel's compiler runtime (libimf, libsvml, libirng,
    # libintlc), which the wheel above does not include or declare as a dependency.
    # https://pypi.org/project/intel-cmplr-lib-rt/#files
    FileSource("https://files.pythonhosted.org/packages/0b/2d/94c431fe41bcc56d9834af652f844721798a139c9f0a7b999e6338aebd0a/intel_cmplr_lib_rt-2026.1.2-py2.py3-none-manylinux_2_28_x86_64.whl",
               "b4a975deeb97eee26c15e7038f63635c4dacc33151506f2e5c56cc5758cbe462"; filename="intel_cmplr_lib_rt-x86_64-linux-gnu.whl"),
    # On Windows, the driver is built with MSVC and loads tbb12.dll at run time, so it needs
    # an MSVC build of oneTBB rather than our MinGW-built oneTBB_jll.
    ArchiveSource("https://github.com/uxlfoundation/oneTBB/releases/download/v2023.1.0/oneapi-tbb-2023.1.0-win.zip",
                  "cf6ee0c600fcb5c3a9b65e3e6e4781669d06f1bb1e37970d145fcde08eed8da9"; unpack_target="oneTBB-x86_64-w64-mingw32"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
unzip -q -d intel_opencl_rt intel_opencl_rt-${target}.whl

# The driver locates its builtin libraries (*.rtl, *.o), the SVML variants and cl.cfg next
# to itself, so everything goes into ${libdir}. Skip the bundled ICD loader (we use
# OpenCL_jll's), import libraries and the gdb helper script.
mkdir -p ${libdir}
if [[ ${target} == *mingw* ]]; then
    cd intel_opencl_rt/intel_opencl_rt-*.data/data/Library/bin
    for f in *; do
        case "$f" in
            OpenCL.dll|*.lib|*-gdb.py) ;;
            *) install -m 755 "$f" ${libdir}/ ;;
        esac
    done
    cd ${WORKSPACE}/srcdir

    cd oneTBB-${target}/oneapi-tbb-*
    install -m 755 redist/intel64/vc14/tbb12.dll redist/intel64/vc14/tbbmalloc.dll ${libdir}/
    install -Dm 644 LICENSE.txt ${prefix}/share/licenses/${SRC_NAME}/oneTBB_LICENSE.txt
    cd ${WORKSPACE}/srcdir
else
    cd intel_opencl_rt/intel_opencl_rt-*.data/data/lib
    for f in *; do
        case "$f" in
            libOpenCL.so*|*-gdb.py) ;;
            # wheels can't hold symlinks, so the unversioned names are full copies
            libintelocl.so|libcommon_clang.so) ;;
            *) install -m 755 "$f" ${libdir}/ ;;
        esac
    done
    ln -s $(basename ${libdir}/libintelocl.so.*) ${libdir}/libintelocl.so
    ln -s $(basename ${libdir}/libcommon_clang.so.*) ${libdir}/libcommon_clang.so
    cd ${WORKSPACE}/srcdir

    unzip -q -d intel_cmplr_lib_rt intel_cmplr_lib_rt-${target}.whl
    cd intel_cmplr_lib_rt/intel_cmplr_lib_rt-*.data/data/lib
    install -m 755 libimf.so libsvml.so libirng.so libintlc.so.5 ${libdir}/
    cd ${WORKSPACE}/srcdir
fi

install_license intel_opencl_rt/intel_opencl_rt-*.data/data/share/doc/opencl/licensing/*.txt
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
]

# The OpenCL ICD loader loads the driver, so we don't. Loading it at audit time would also
# fail: libtbb comes from oneTBB_jll, which only has a cxx11 build for x86_64-linux-gnu.
products = [
    LibraryProduct(["libintelocl", "intelocl64"], :libintelocl; dont_dlopen=true),
]

dependencies = [
    Dependency("OpenCL_jll"),
    # the version Intel builds and tests the driver against
    Dependency(PackageSpec(name="oneTBB_jll", uuid="1317d2d5-d96f-522e-a858-c73665f53c3e");
               compat="2023.1", platforms=filter(Sys.islinux, platforms)),
    Dependency("Zlib_jll"; platforms=filter(Sys.islinux, platforms)),
    # the bundled MSVC-built tbb12.dll needs the Visual C++ runtime
    Dependency("MSVCRuntime_jll"; platforms=filter(Sys.iswindows, platforms)),
]

init_block = raw"""
    # Register this driver with OpenCL_jll
    if OpenCL_jll.is_available()
        push!(OpenCL_jll.drivers, libintelocl)
    end
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", lazy_artifacts=true, init_block)
