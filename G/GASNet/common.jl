gasnet_conduit_name(x) = "GASNet_conduit_$x"

version = v"2024.5.0"

sources = [
    ArchiveSource("https://gasnet.lbl.gov/EX/GASNet-2024.5.0.tar.gz", "f945e80f71d340664766b66290496d230e021df5e5cd88f404d101258446daa9"),
]

platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="gnu"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

# TODO checkout
# --enable-debug - build GASNet in a debugging mode. This turns on C-level
#   debugger options and also enables extensive error and sanity checking 
#   system-wide, which is highly recommended for developing and debugging 
#   GASNet clients (but should NEVER be used for performance testing). 
#   --enable-debug also implies --enable-{trace,stats,debug-malloc},
#   but these can still be selectively --disable'd.
# --enable-trace - turn on GASNet tracing (see usage info below)
# --enable-stats - turn on GASNet statistical collection (see usage info below)
# --enable-debug-malloc - use GASNet debugging malloc (see usage info below)
# --enable-segment-{fast,large,everything} - select a GASNet segment 
#   configuration (see the GASNet spec for more info)
# --enable-pshm - Build GASNet with inter-Process SHared Memory (PSHM) support.
#   This feature uses shared memory communication among the processes (aka
#   GASNet nodes) within a single compute node (where the other alternatives
#   are multi-threading via a PAR or PARSYNC build; or use of the conduit's
#   API to perform the communication).
#   Note that not all conduits and operating systems support this feature.
#   For more information, see the section below entitled "GASNet inter-Process
#   SHared Memory (PSHM)".


# recommendations for systems:
# On HPE Cray EX (aka "Shasta") systems, we recommend the following configure
#   arguments to use the vendor's compiler wrappers:
#     --with-cc=cc --with-cxx=CC --with-mpi-cc=cc
#   Additionally, exactly one of the following is recommended to ensure that
#   ofi-conduit is built for the appropriate libfabric provider:
#     * HPE Cray EX with Slingshot-10 (100Gbps) NICs: --with-ofi-provider=verbs
#     * HPE Cray EX with Slingshot-11 (200Gbps) NICs: --with-ofi-provider=cxi
#     * HPE Cray EX with BOTH NIC types: --with-ofi-provider=generic
# On Linux clusters with Omni-Path networks from Intel or Cornelis Networks, we
#   recommend the following configure arguments to avoid using ibv-conduit over
#   an emulated libibverbs:
#     --disable-ibv --enable-ofi --with-ofi-provider=psm2
# for linux-infiniband: --enable-mpi --disable-ibv --disable-ofi
