# Aurora dgpu LTS — currently pinned to LTS 2523.40.
#
# Per-package pins for the current point release are listed at:
#   https://dgpu-docs.osgc.infra-host.com/releases/packages.html?release=LTS+<X.Y>&os=all
# General LTS line tracking:
#   https://docs.alcf.anl.gov/aurora/system-updates/
#   https://dgpu-docs.osgc.infra-host.com/releases/release-notes.html
#
# When Aurora ticks to a new point release (e.g. 2523.41) or a new LTS line
# (e.g. 2624.x), bump `version`, `api_version` (if the API moved), the
# GitSource commit, and the LTS comment annotations below — in place. The
# resulting JLLs (`oneAPI_Level_Zero_Headers_LTS_jll`,
# `oneAPI_Level_Zero_Loader_LTS_jll`) follow Aurora's tip; users that need a
# specific Aurora release should pin via Pkg version compat (e.g.
# `oneAPI_Level_Zero_Loader_LTS_jll = "=1.24.0"` for LTS 2523.40).

version     = v"1.24.0"   # libze1 / libze-dev shipped in LTS 2523.40
api_version = v"1.13.0"   # ZE_API_VERSION_CURRENT at v1.24.0

sources = BinaryBuilder.AbstractSource[
    GitSource("https://github.com/oneapi-src/level-zero.git",
              "9402907a3ce6987871325e4e1329e053b8e5cf2b"),  # tag v1.24.0
]
