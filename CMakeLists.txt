cmake_minimum_required(VERSION 3.20)
project(tModLite CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Direkter Download der offiziellen Single-Header-Release-Datei statt
# git-Clone des ganzen Repos ueber FetchContent(GIT_REPOSITORY): in dieser
# Umgebung haengt sich der git-smart-HTTP-Transport beim Clone auf, waehrend
# einfache HTTPS-Downloads (curl/file(DOWNLOAD)) zuverlaessig funktionieren.
# Wird in ein nlohmann/-Unterverzeichnis gelegt, damit #include
# <nlohmann/json.hpp> unveraendert funktioniert.
set(NLOHMANN_JSON_INCLUDE_DIR "${CMAKE_BINARY_DIR}/_deps/nlohmann_json_single_header")
file(MAKE_DIRECTORY "${NLOHMANN_JSON_INCLUDE_DIR}/nlohmann")
file(DOWNLOAD
    "https://github.com/nlohmann/json/releases/download/v3.11.3/json.hpp"
    "${NLOHMANN_JSON_INCLUDE_DIR}/nlohmann/json.hpp"
    STATUS NLOHMANN_JSON_DOWNLOAD_STATUS
)
list(GET NLOHMANN_JSON_DOWNLOAD_STATUS 0 NLOHMANN_JSON_DOWNLOAD_CODE)
if(NOT NLOHMANN_JSON_DOWNLOAD_CODE EQUAL 0)
    message(FATAL_ERROR "Download von nlohmann/json.hpp fehlgeschlagen: ${NLOHMANN_JSON_DOWNLOAD_STATUS}")
endif()

add_library(nlohmann_json INTERFACE)
add_library(nlohmann_json::nlohmann_json ALIAS nlohmann_json)
target_include_directories(nlohmann_json INTERFACE "${NLOHMANN_JSON_INCLUDE_DIR}")

add_subdirectory(src/core)

if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    add_subdirectory(src/platform/ios)
endif()

if(NOT CMAKE_SYSTEM_NAME MATCHES "iOS|Android")
    add_subdirectory(src/sim)
endif()
