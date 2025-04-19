# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(flutter_serial_library VERSION 0.0.1 LANGUAGES C)

if (WIN32)
  add_library(flutter_serial SHARED
    "libserialport/serialport.c"
    "libserialport/timing.c"
    "libserialport/windows.c"
  )
  target_compile_definitions(flutter_serial PUBLIC DART_SHARED_LIB LIBSERIALPORT_MSBUILD)
  target_link_libraries(flutter_serial PRIVATE cfgmgr32 SetupAPI)
else()
  add_library(flutter_serial SHARED
    "libserialport/serialport.c"
    "libserialport/timing.c"
    "libserialport/linux.c"
    "libserialport/linux_termios.c"
  )
  target_compile_options(flutter_serial PRIVATE
    -std=c99 -Wall -Wextra -pedantic -Wmissing-prototypes -Wshadow)
  target_compile_definitions(flutter_serial PRIVATE LIBSERIALPORT_ATBUILD)
endif()

set_target_properties(flutter_serial PROPERTIES
  PUBLIC_HEADER libserialport/libserialport.h
  OUTPUT_NAME "flutter_serial"
)

target_include_directories(flutter_serial PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/libserialport"
)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(flutter_serial PRIVATE "-Wl,-z,max-page-size=16384")
endif()
