driver = "470.57.02"

sources = [
    FileSource("https://us.download.nvidia.com/tesla/$driver/NVIDIA-Linux-x86_64-$driver.run",
               "55d7ae104827faa79e975321fe2b60f9dd42fbff65642053443c0e56fdb4c47d", "installer.run")
]

platforms = [Platform("x86_64", "linux"; cuda="11.4")]
