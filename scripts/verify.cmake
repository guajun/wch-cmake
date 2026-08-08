cmake_minimum_required(VERSION 3.24)

if(NOT DEFINED WCH_PROJECT OR WCH_PROJECT STREQUAL "")
    message(FATAL_ERROR "WCH_PROJECT is required")
endif()
if(NOT DEFINED WCH_MRS_BUILD OR WCH_MRS_BUILD STREQUAL "")
    set(WCH_MRS_BUILD "obj")
endif()
if(NOT DEFINED WCH_CMAKE_BUILD OR WCH_CMAKE_BUILD STREQUAL "")
    set(WCH_CMAKE_BUILD "build/release")
endif()
if(NOT DEFINED ENV{MRS2_ROOT} OR "$ENV{MRS2_ROOT}" STREQUAL "")
    message(FATAL_ERROR
        "MRS2_ROOT is not set. Run the generated activation script or export "
        "MRS2_ROOT before verifying this project.")
endif()
file(TO_CMAKE_PATH "$ENV{MRS2_ROOT}" MRS2_ROOT)

get_filename_component(WCH_PROJECT "${WCH_PROJECT}" ABSOLUTE)
file(TO_CMAKE_PATH "${WCH_PROJECT}" WCH_PROJECT)
include("${WCH_PROJECT}/cmake/wch-project.cmake")

if(WIN32)
    set(_exe ".exe")
else()
    set(_exe "")
endif()
set(_toolchain_bin
    "${MRS2_ROOT}/resources/app/resources/win32/components/WCH/Toolchain/${WCH_TOOLCHAIN_NAME}/bin")
set(_objcopy "${_toolchain_bin}/${WCH_TOOL_PREFIX}objcopy${_exe}")
set(_nm "${_toolchain_bin}/${WCH_TOOL_PREFIX}nm${_exe}")
foreach(_tool IN ITEMS "${_objcopy}" "${_nm}")
    if(NOT EXISTS "${_tool}")
        message(FATAL_ERROR "Missing WCH tool: ${_tool}")
    endif()
endforeach()

set(_mrs_elf "${WCH_PROJECT}/${WCH_MRS_BUILD}/${WCH_ARTIFACT_BASENAME}.elf")
set(_cmake_elf "${WCH_PROJECT}/${WCH_CMAKE_BUILD}/${WCH_ARTIFACT_BASENAME}.elf")
foreach(_elf IN ITEMS "${_mrs_elf}" "${_cmake_elf}")
    if(NOT EXISTS "${_elf}")
        message(FATAL_ERROR "Firmware ELF not found: ${_elf}")
    endif()
endforeach()

set(_temporary "${WCH_PROJECT}/build/.wch-verify")
file(REMOVE_RECURSE "${_temporary}")
file(MAKE_DIRECTORY "${_temporary}")
set(_mrs_bin "${_temporary}/mrs.bin")
set(_cmake_bin "${_temporary}/cmake.bin")

execute_process(
    COMMAND "${_objcopy}" -O binary "${_mrs_elf}" "${_mrs_bin}"
    RESULT_VARIABLE _mrs_objcopy_status
    ERROR_VARIABLE _mrs_objcopy_error)
execute_process(
    COMMAND "${_objcopy}" -O binary "${_cmake_elf}" "${_cmake_bin}"
    RESULT_VARIABLE _cmake_objcopy_status
    ERROR_VARIABLE _cmake_objcopy_error)
if(NOT _mrs_objcopy_status EQUAL 0 OR NOT _cmake_objcopy_status EQUAL 0)
    file(REMOVE_RECURSE "${_temporary}")
    message(FATAL_ERROR "objcopy failed: ${_mrs_objcopy_error}${_cmake_objcopy_error}")
endif()

file(SHA256 "${_mrs_bin}" _mrs_image_sha)
file(SHA256 "${_cmake_bin}" _cmake_image_sha)
set(_mrs_hex "${WCH_PROJECT}/${WCH_MRS_BUILD}/${WCH_ARTIFACT_BASENAME}.hex")
set(_cmake_hex "${WCH_PROJECT}/${WCH_CMAKE_BUILD}/${WCH_ARTIFACT_BASENAME}.hex")
set(_hex_equal OFF)
if(EXISTS "${_mrs_hex}" AND EXISTS "${_cmake_hex}")
    file(SHA256 "${_mrs_hex}" _mrs_hex_sha)
    file(SHA256 "${_cmake_hex}" _cmake_hex_sha)
    if(_mrs_hex_sha STREQUAL _cmake_hex_sha)
        set(_hex_equal ON)
    endif()
endif()

execute_process(
    COMMAND "${_nm}" -n "${_mrs_elf}"
    RESULT_VARIABLE _mrs_nm_status
    OUTPUT_VARIABLE _mrs_symbols
    ERROR_VARIABLE _mrs_nm_error)
execute_process(
    COMMAND "${_nm}" -n "${_cmake_elf}"
    RESULT_VARIABLE _cmake_nm_status
    OUTPUT_VARIABLE _cmake_symbols
    ERROR_VARIABLE _cmake_nm_error)
if(NOT _mrs_nm_status EQUAL 0 OR NOT _cmake_nm_status EQUAL 0)
    file(REMOVE_RECURSE "${_temporary}")
    message(FATAL_ERROR "nm failed: ${_mrs_nm_error}${_cmake_nm_error}")
endif()
string(REPLACE "\r\n" "\n" _mrs_symbols "${_mrs_symbols}")
string(REPLACE "\r\n" "\n" _cmake_symbols "${_cmake_symbols}")
if(_mrs_symbols STREQUAL _cmake_symbols)
    set(_symbols_equal ON)
else()
    set(_symbols_equal OFF)
endif()

file(REMOVE_RECURSE "${_temporary}")
if(NOT _mrs_image_sha STREQUAL _cmake_image_sha OR NOT _hex_equal OR NOT _symbols_equal)
    message(FATAL_ERROR
        "Firmware mismatch: image=${_mrs_image_sha}/${_cmake_image_sha}, "
        "hex=${_hex_equal}, symbols=${_symbols_equal}")
endif()
message(STATUS "MRS2 and CMake firmware match: ${_mrs_image_sha}")
