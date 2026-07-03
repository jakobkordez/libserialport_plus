/* config.h values used when building libserialport through Dart native assets. */

/* clock_gettime is available. */
#define HAVE_CLOCK_GETTIME 1

/* Define to 1 if you have the declaration of `BOTHER', and to 0 if you don't. */
#if defined(__APPLE__)
#define HAVE_DECL_BOTHER 0
#else
#define HAVE_DECL_BOTHER 1
#endif

/* Define to 1 if you have the <dlfcn.h> header file. */
#define HAVE_DLFCN_H 1

/* flock is available. */
#define HAVE_FLOCK 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* realpath is available. */
#define HAVE_REALPATH 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdio.h> header file. */
#define HAVE_STDIO_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if the system has the type `struct serial_struct'. */
#if defined(__linux__) && !defined(__ANDROID__)
#define HAVE_STRUCT_SERIAL_STRUCT 1
#endif

/* Define to 1 if the system has the type `struct termios2'. */
#if defined(__linux__)
#define HAVE_STRUCT_TERMIOS2 1
#define HAVE_STRUCT_TERMIOS2_C_ISPEED 1
#define HAVE_STRUCT_TERMIOS2_C_OSPEED 1
#endif

/* sys/file.h is available. */
#define HAVE_SYS_FILE_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to the sub-directory where libtool stores uninstalled libraries. */
#define LT_OBJDIR ".libs/"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "martin-libserialport@earth.li"

/* Define to the full name of this package. */
#define PACKAGE_NAME "libserialport"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libserialport 0.1.1"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libserialport"

/* Define to the home page for this package. */
#define PACKAGE_URL "http://sigrok.org/wiki/Libserialport"

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.1.1"

/* Macro preceding public API functions */
#define SP_API __attribute__((visibility("default")))

/* . */
#define SP_LIB_VERSION_AGE 1

/* . */
#define SP_LIB_VERSION_CURRENT 1

/* . */
#define SP_LIB_VERSION_REVISION 0

/* . */
#define SP_LIB_VERSION_STRING "1:0:1"

/* . */
#define SP_PACKAGE_VERSION_MAJOR 0

/* . */
#define SP_PACKAGE_VERSION_MICRO 1

/* . */
#define SP_PACKAGE_VERSION_MINOR 1

/* . */
#define SP_PACKAGE_VERSION_STRING "0.1.1"

/* Macro preceding private functions */
#define SP_PRIV __attribute__((visibility("hidden")))

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Enable large inode numbers on Mac OS X 10.5. */
#ifndef _DARWIN_USE_64_BIT_INODE
#define _DARWIN_USE_64_BIT_INODE 1
#endif

#if defined(HAVE_STRUCT_TERMIOS_C_ISPEED) && \
    defined(HAVE_STRUCT_TERMIOS_C_OSPEED)
#define HAVE_TERMIOS_SPEED 1
#endif
#if defined(HAVE_STRUCT_TERMIOS2_C_ISPEED) && \
    defined(HAVE_STRUCT_TERMIOS2_C_OSPEED)
#define HAVE_TERMIOS2_SPEED 1
#endif
