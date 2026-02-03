cmake_minimum_required(VERSION 3.15)
project(PROPOSAL_cxxwrap LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find JlCxx (CxxWrap C++ library)
find_package(JlCxx REQUIRED)

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
