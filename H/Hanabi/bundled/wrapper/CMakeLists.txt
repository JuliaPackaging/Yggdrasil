cmake_minimum_required(VERSION 3.8.0)
project(hanabi)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(hanabi SHARED)

target_sources(hanabi PRIVATE ./hanabi_lib/hanabi_card.cc)
target_sources(hanabi PRIVATE ./hanabi_lib/hanabi_game.cc)
target_sources(hanabi PRIVATE ./hanabi_lib/hanabi_hand.cc)
target_sources(hanabi PRIVATE ./hanabi_lib/hanabi_history_item.cc)
target_sources(hanabi PRIVATE ./hanabi_lib/hanabi_move.cc)
target_sources(hanabi PRIVATE ./hanabi_lib/hanabi_observation.cc)
target_sources(hanabi PRIVATE ./hanabi_lib/hanabi_state.cc)
target_sources(hanabi PRIVATE ./hanabi_lib/util.cc)
target_sources(hanabi PRIVATE ./hanabi_lib/canonical_encoders.cc)
target_sources(hanabi PRIVATE ./pyhanabi.cc)
        
target_include_directories(hanabi PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/hanabi_lib>
        $<INSTALL_INTERFACE:include>)

target_compile_features(hanabi PRIVATE cxx_std_11)

set_property(TARGET hanabi APPEND PROPERTY PUBLIC_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/pyhanabi.h)

install(TARGETS hanabi
        EXPORT hanabi-targets
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        PUBLIC_HEADER DESTINATION include)

install(EXPORT hanabi-targets
        FILE hanabi-config.cmake
        DESTINATION lib/cmake/hanabi)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/compile_commands.json DESTINATION share)
