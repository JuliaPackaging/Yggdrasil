# Shared by VkFFT_CUDA, VkFFT_Metal and VkFFT_OpenCL.
#
# VkFFT picks its backend at compile time, so each of the three packages builds
# this same wrapper with a different VKFFT_BACKEND and ships one library. We
# want to keep the commit of libvkfft the same across all JLLs, so we define
# it here.

version = v"0.1.0"

# The commit the v0.1.0 tag of libvkfft points at.
const libvkfft_commit = "8d20a59e32bcacdc8ae09ba71ce4589719cd7257"

sources = [
    GitSource("https://github.com/PaulVirally/libvkfft.git", libvkfft_commit),
]

products = [
    LibraryProduct("libvkfft", :libvkfft),
]
