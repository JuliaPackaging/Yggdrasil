cmake_minimum_required(VERSION 3.15)
project(PROPOSAL_cxxwrap LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find JlCxx (CxxWrap C++ library)
find_package(JlCxx REQUIRED)

# Remove C++20 compile feature from JlCxx to avoid nlohmann_json incompatibility
# JlCxx propagates cxx_std_20 which breaks nlohmann_json's std::u8string usage
get_target_property(JLCXX_COMPILE_FEATURES JlCxx::cxxwrap_julia INTERFACE_COMPILE_FEATURES)
if(JLCXX_COMPILE_FEATURES)
    list(FILTER JLCXX_COMPILE_FEATURES EXCLUDE REGEX "cxx_std_.*")
    set_target_properties(JlCxx::cxxwrap_julia PROPERTIES INTERFACE_COMPILE_FEATURES "${JLCXX_COMPILE_FEATURES}")
endif()

# Find PROPOSAL
find_package(PROPOSAL REQUIRED)

# Create the wrapper library
add_library(PROPOSAL_cxxwrap SHARED PROPOSAL_cxxwrap.cxx)

target_include_directories(PROPOSAL_cxxwrap PRIVATE
    ${JlCxx_INCLUDE_DIRS}
)

target_link_libraries(PROPOSAL_cxxwrap
    PRIVATE
    JlCxx::cxxwrap_julia
    PROPOSAL::PROPOSAL
)

# Force C++17 to avoid nlohmann_json C++20 incompatibility with std::u8string
# JlCxx propagates C++20 via interface compile features, so we must override explicitly
set_target_properties(PROPOSAL_cxxwrap PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)
target_compile_options(PROPOSAL_cxxwrap PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-std=c++17>)

# Apple-specific: avoid dlopen deadlock by deferring symbol resolution
if(APPLE)
    target_link_options(PROPOSAL_cxxwrap PRIVATE "LINKER:-undefined,dynamic_lookup")
    set_target_properties(JlCxx::cxxwrap_julia PROPERTIES
        INTERFACE_LINK_LIBRARIES "-framework CoreFoundation"
    )
endif()

# Install rules
install(TARGETS PROPOSAL_cxxwrap
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
