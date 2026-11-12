# In the Windows section, modify the compiler flags and linking section:
if(WIN32)
    # For MinGW/GCC, use appropriate flags, not MSVC style
    if(MSVC)
        # Original MSVC-specific code
        string(REPLACE "/GR" " " CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
        if(CMAKE_BUILD_TYPE MATCHES Debug)
            set_target_properties(${PROJECT_NAME} PROPERTIES
                COMPILE_FLAGS "/source-charset:utf-8 /GR-"
                )
        else()
            set_target_properties(${PROJECT_NAME} PROPERTIES
                COMPILE_FLAGS "/source-charset:utf-8 /Gw /GL /GR-"
                )
        endif()
        # MSVC-specific delay load logic
        set(DELAYFLAGS)
        list(APPEND DELAYFLAGS
                "/DELAYLOAD:api-ms-win-core-winrt-string-l1-1-0.dll"
                "/DELAYLOAD:api-ms-win-core-winrt-l1-1-0.dll")
        string(REPLACE ";" " " DELAYFLAGS "${DELAYFLAGS}")
        set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY LINK_FLAGS "${DELAYFLAGS} /LTCG")
        set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY LINK_FLAGS " /DEF:${CMAKE_CURRENT_BINARY_DIR}/windowsexports.def")
        if(USE_STATIC_MSVC)
            if(CMAKE_BUILD_TYPE MATCHES Debug)
                set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY LINK_FLAGS " /NODEFAULTLIB:MSVCRTD")
            else()
                set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY LINK_FLAGS " /NODEFAULTLIB:MSVCRT")
            endif()
        endif()

        target_link_libraries(${PROJECT_NAME} PRIVATE runtimeobject.lib delayimp.lib)
    else() # Non-MSVC Windows compiler (MinGW)
        # MinGW specific flags
        string(REPLACE "-fexceptions" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
        
        set_target_properties(${PROJECT_NAME} PROPERTIES
                COMPILE_FLAGS "-finput-charset=utf-8 -fdata-sections"
                )
        
        # Explicitly disable LTO and use output-def
        set_property(TARGET ${PROJECT_NAME} APPEND_STRING PROPERTY LINK_FLAGS "-fno-lto")
    endif()

    target_link_libraries(${PROJECT_NAME} PRIVATE bcrypt crypt32 wintrust)
endif()
