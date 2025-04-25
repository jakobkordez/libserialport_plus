# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(libserialport_plus_library VERSION 0.0.1 LANGUAGES C)

if (WIN32)
  add_library(libserialport_plus SHARED
    "libserialport/serialport.c"
    "libserialport/timing.c"
    "libserialport/windows.c"
  )
  target_compile_definitions(libserialport_plus PUBLIC DART_SHARED_LIB LIBSERIALPORT_MSBUILD)
  target_link_libraries(libserialport_plus PRIVATE cfgmgr32 SetupAPI)
else()
  add_library(libserialport_plus SHARED
    "libserialport/serialport.c"
    "libserialport/timing.c"
    "libserialport/linux.c"
    "libserialport/linux_termios.c"
  )
  target_compile_options(libserialport_plus PRIVATE
    -std=c99 -Wall -Wextra -pedantic -Wmissing-prototypes -Wshadow)
  target_compile_definitions(libserialport_plus PRIVATE LIBSERIALPORT_ATBUILD)
endif()

set_target_properties(libserialport_plus PROPERTIES
  PUBLIC_HEADER libserialport/libserialport.h
  OUTPUT_NAME "libserialport_plus"
)

target_include_directories(libserialport_plus PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/libserialport"
)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(libserialport_plus PRIVATE "-Wl,-z,max-page-size=16384")
endif()
