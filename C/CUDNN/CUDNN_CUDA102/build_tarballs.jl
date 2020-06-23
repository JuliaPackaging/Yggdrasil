using BinaryBuilder

cuda_version = v"10.2.89"   # NOTE: could be less specific

sources_linux = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.2_20191118/cudnn-10.2-linux-x64-v7.6.5.32.tgz",
                  "600267f2caaed2fd58eb214ba669d8ea35f396a7d19b94822e6b36f9f7088c20")
]
sources_windows = [
    ArchiveSource("https://developer.nvidia.com/compute/machine-learning/cudnn/secure/7.6.5.32/Production/10.2_20191118/cudnn-10.2-windows10-x64-v7.6.5.32.zip",
                  "fba812f60c61bc33b81db06cd55e8d769774d036186571d724295c71c9936064")
]

include("../common.jl")
