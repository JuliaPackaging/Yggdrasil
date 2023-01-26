# CUDA forward compatibility driver
#
# - https://docs.nvidia.com/deploy/cuda-compatibility/index.html#forward-compatibility-title
# - https://docs.nvidia.com/datacenter/tesla/index.html
# - https://www.nvidia.com/Download/index.aspx

using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_Driver"
version = v"0.3"

cuda_version = v"12.0"
cuda_version_str = "$(cuda_version.major)-$(cuda_version.minor)"
driver_version_str = "525.60.13"
build = 1

sources_linux_x86 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-compat-$(cuda_version_str)-$(driver_version_str)-$(build).x86_64.rpm",
               "9c495dfe7f5abde58c9446ce4e21e80623e5942db00f8d7500047895e7676b69", "compat.rpm")
]
sources_linux_ppc64le = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/ppc64le/cuda-compat-$(cuda_version_str)-$(driver_version_str)-$(build).ppc64le.rpm",
               "568f0167405c911731177aea6277a64de95e488b5770babe0f72c89790bcf02f", "compat.rpm")
]
sources_linux_aarch64 = [
    FileSource("https://developer.download.nvidia.com/compute/cuda/repos/rhel8/sbsa/cuda-compat-$(cuda_version_str)-$(driver_version_str)-$(build).aarch64.rpm",
               "a791a355addeab181ca78a088b87dbda7468cd58bb8ef22a21db6bdb688faacc", "compat.rpm")
]

dependencies = []

script = raw"""
    apk update
    apk add rpm2cpio
    rpm2cpio compat.rpm | cpio -idmv

    mkdir -p ${libdir}

    mv usr/local/cuda-*/compat/* ${libdir}
"""

# CUDA_Driver_jll provides libcuda_compat, but we can't always use that driver: It requires
# specific hardware, and a compatible operating system. So we don't just dlopen the library,
# but instead check during __init__ if we can, and dlopen either the system driver or the
# compatible one from this JLL.
#
# Ordinarily, we'd put this logic in a package that depends on CUDA_Driver_jll (e.g.
# CUDA_Driver.jl), but that complicates depending on it from other JLLs (like
# CUDA_Runtime_jll). This will also simplify moving the logic into CUDA_Runtime_jll, which
# we will have to at some point (because its pkg hooks shouldn't depend on CUDA_Driver_jll).
init_block = """
    global compat_version = $(repr(cuda_version))
""" * raw"""
    # global variables we will set
    global libcuda
    global libcuda_version
    global libcuda_original_version

    # minimal API call wrappers we need
    function driver_version(library_handle)
        function_handle = Libdl.dlsym(library_handle, "cuDriverGetVersion")
        version_ref = Ref{Cint}()
        status = ccall(function_handle, Cint, (Ptr{Cint},), version_ref)
        if status != 0
            return nothing
        end
        major, ver = divrem(version_ref[], 1000)
        minor, patch = divrem(ver, 10)
        return VersionNumber(major, minor, patch)
    end
    function init_driver(library_handle)
        function_handle = Libdl.dlsym(library_handle, "cuInit")
        status = ccall(function_handle, Cint, (UInt32,), 0)
        Libdl.dlclose(library_handle)
        return status
    end

    # find the system driver
    system_driver = if Sys.iswindows()
        Libdl.find_library("nvcuda")
    else
        Libdl.find_library(["libcuda.so.1", "libcuda.so"])
    end
    if system_driver == ""
        @debug "No system CUDA driver found"
        return
    end
    libcuda = system_driver

    # check if the system driver is already loaded. in that case, we have to use it because
    # the code that loaded it in the first place might have made assumptions based on it.
    system_driver_loaded = Libdl.dlopen(system_driver, Libdl.RTLD_NOLOAD;
                                        throw_error=false) !== nothing
    driver_handle = Libdl.dlopen(system_driver; throw_error=true)

    # query the system driver version
    # XXX: apparently cuDriverGetVersion can be used before cuInit,
    #      despite the docs stating "any function [...] will return
    #      CUDA_ERROR_NOT_INITIALIZED"; is this a recent change?
    system_version = driver_version(driver_handle)
    if system_version === nothing
        @debug "Failed to query system CUDA driver version"
        # note that libcuda is already set here, so we'll continue using the system driver
        # and CUDA.jl will likely report the reason cuDriverGetVersion didn't work.
        return
    end
    @debug "System CUDA driver found at $system_driver, detected as version $system_version"
    libcuda = system_driver
    libcuda_version = system_version

    # check if the system driver is already loaded (see above)
    if system_driver_loaded
        @debug "System CUDA driver already loaded, continuing using it"
        return
    end

    # check the user preference
    if !parse(Bool, get(ENV, "JULIA_CUDA_USE_COMPAT", "true"))
        @debug "User disallows using forward-compatible driver."
        return
    end

    # check the version
    if system_version >= compat_version
        @debug "System CUDA driver is recent enough; not using forward-compatible driver"
        return
    end

    # check if we can unload the system driver.
    # if we didn't, we can't consider a forward compatible library because that would
    # risk having multiple copies of libcuda.so loaded (also see NVIDIA bug #3418723)
    Libdl.dlclose(driver_handle)
    system_driver_loaded = Libdl.dlopen(system_driver, Libdl.RTLD_NOLOAD;
                                        throw_error=false) !== nothing
    if system_driver_loaded
        @debug "Could not unload the system CUDA library;" *
               " this prevents use of the forward-compatible driver"
        return
    end

    # check if this process is hooked by CUDA's injection libraries, which prevents
    # unloading libcuda after dlopening. this is problematic, because we might want to
    # after loading a forwards-compatible libcuda and realizing we can't use it. without
    # being able to unload the library, we'd run into issues (see NVIDIA bug #3418723)
    hooked = haskey(ENV, "CUDA_INJECTION64_PATH")
    if hooked
        @debug "Running under CUDA injection tools;" *
               " this prevents use of the forward-compatible driver"
        return
    end

    # check if we even have an artifact
    if !@isdefined(libcuda_compat)
        @debug "No forward-compatible CUDA library available for your platform."
        return
    end
    compat_driver = libcuda_compat
    @debug "Forward-compatible CUDA driver found at $compat_driver;" *
           " reported as version $(compat_version)"

    # finally, load the compatibility driver to see if it supports this platform
    driver_handle = Libdl.dlopen(compat_driver; throw_error=true)
    # TODO: do we need to dlopen the JIT compiler library for it to be discoverable?
    #       doesn't that clash with a system one if compat cuInit fails? or should
    #       we load it _after_ the compat driver initialization succeeds?
    #compiler_handle = libnvidia_ptxjitcompiler
    #Libdl.dlopen(compiler_handle)

    init_status = init_driver(driver_handle)
    if init_status != 0
        @debug "Could not use forward compatibility package (error $init_status)"

        # see comment above about unloading the system driver
        Libdl.dlclose(driver_handle)
        compat_driver_loaded = Libdl.dlopen(compat_driver, Libdl.RTLD_NOLOAD;
                                            throw_error=false) !== nothing
        if compat_driver_loaded
            error("Could not unload the forward compatible CUDA driver library." *
                  "This is probably caused by running Julia under a tool that hooks CUDA API calls." *
                  "In that case, prevent Julia from loading multiple drivers" *
                  " by setting JULIA_CUDA_USE_COMPAT=false in your environment.")
        end

        return
    end

    @debug "Successfully loaded forwards-compatible CUDA driver"
    libcuda = compat_driver
    libcuda_version = compat_version
    libcuda_original_version = system_version
"""

products = [
    LibraryProduct("libcuda", :libcuda_compat; dont_dlopen=true),
    LibraryProduct("libnvidia-ptxjitcompiler", :libnvidia_ptxjitcompiler;
                   dont_dlopen=true),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_x86, script,
                   [Platform("x86_64", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true, init_block)
end

if should_build_platform("powerpc64le-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Platform("powerpc64le", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true, init_block)
end

if should_build_platform("aarch64-linux-gnu")
    build_tarballs(ARGS, name, version, sources_linux_aarch64, script,
                   [Platform("aarch64", "linux")], products, dependencies;
                   lazy_artifacts=true, skip_audit=true, init_block)
end
