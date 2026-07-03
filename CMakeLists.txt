cmake_minimum_required(VERSION 3.20)
project(tModLite CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

add_subdirectory(src/core)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    add_subdirectory(src/platform/ios)
endif()

if(NOT CMAKE_SYSTEM_NAME MATCHES "iOS|Android")
    add_subdirectory(src/sim)
endif()
