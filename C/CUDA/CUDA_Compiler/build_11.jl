products = [
    FileProduct(["lib/libcudadevrt.a", "lib/cudadevrt.lib"], :libcudadevrt),
    FileProduct("share/libdevice/libdevice.10.bc", :libdevice),
    ExecutableProduct("ptxas", :ptxas),
    ExecutableProduct("nvdisasm", :nvdisasm),
    ExecutableProduct("nvlink", :nvlink),
]
