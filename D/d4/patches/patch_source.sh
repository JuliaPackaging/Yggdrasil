#!/bin/bash

# 1. Fixes for headers and C++ compatibility (Glucose 3.0)
# Even in d4v2, Glucose still uses fpu_control.h on linux without checking for glibc
sed -i 's/#if defined(__linux__)/#if defined(__linux__) \&\& defined(__GLIBC__)/g' 3rdParty/glucose-3.0/utils/System.h
sed -i 's/#if defined(__linux__)/#if defined(__linux__) \&\& defined(__GLIBC__)/g' 3rdParty/glucose-3.0/utils/System.cc

# Fix for u_int types which are not standard
find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -exec sed -i 's/u_int\([0-9]\+\)_t/uint\1_t/g' {} +

# Fix for 1UL << 32 overflow (should be 1ULL)
find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -exec sed -i 's/1UL << 32/1ULL << 32/g' {} +

# 2. Windows specific fixes
if [[ "${target}" == *mingw* ]]; then
    # Disable signal handling that is not available on Windows
    find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -exec sed -i 's/signal(SIGALRM, /#ifndef _WIN32\nsignal(SIGALRM, /g' {} +
    find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -exec sed -i 's/handler);/handler);\n#endif/g' {} +
    find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -exec sed -i 's/alarm(\([^)]*\));/#ifndef _WIN32\nalarm(\1);\n#endif/g' {} +
fi

# 3. Remove/Disable PaToH support (since it's a proprietary library usually not in JLL)
sed -i 's/#include "PartitionerPatoh.hpp"/\/\/ #include "PartitionerPatoh.hpp"/' src/partitioner/PartitionerManager.cpp
sed -i 's/return new PartitionerPatoh(infoHyperGraph, out);/throw(std::runtime_error("Partitioner PaToH not supported"));/' src/partitioner/PartitionerManager.cpp
# Also disable Kahypar if not found (d4v2 seems to expect it in 3rdParty)
# We will handle this via CMake by not including the files if they are missing
