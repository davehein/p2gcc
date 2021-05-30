# Find propeller-elf-gcc in order to build the libraries
find_program(PROPGCC propeller-elf-gcc
    PATHS /opt/parallax/bin)
find_program(PROPGCC_AR propeller-elf-ar
    PATHS /opt/parallax/bin)
if (NOT PROPGCC)
    message(FATAL_ERROR "Can't find PropGCC and therefore can not build p2gcc's standard libraries.")
endif ()
if (NOT PROPGCC_AR)
    message(FATAL_ERROR "Can't find PropGCC's archiver and therefore can not build p2gcc's standard libraries.")
endif ()

if (WIN32 AND NOT "${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "Windows")
    # When cross-compiling for Windows from Linux or Mac, use Wine to invoke the versions of s2pasm and p2asm that we
    # just built
    find_program(WINE wine)
    if (NOT WINE)
        message(FATAL_ERROR "Unable to build p2gcc's libraries from ${CMAKE_HOST_SYSTEM_NAME} without Wine")
    endif ()
endif ()

function(c2o libname)
    add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${libname}.s"
        COMMAND "${PROPGCC}" -Wall -mcog -O2 -m32bit-doubles -S "${CMAKE_CURRENT_LIST_DIR}/${libname}.c"
        DEPENDS "${CMAKE_CURRENT_LIST_DIR}/${libname}.c"
    )
    s2o("${libname}" 0)
endfunction()

function(s2o libname copy_is_needed)
    if (copy_is_needed)
        # Copy the source to the binary directory so the generated output doesn't clutter the source dir
        add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${libname}.s"
            COMMAND "${CMAKE_COMMAND}" -E copy "${CMAKE_CURRENT_LIST_DIR}/${libname}.s" "${libname}.s"
            DEPENDS "${CMAKE_CURRENT_LIST_DIR}/${libname}.s"
        )
    endif ()

    add_custom_command(OUTPUT "${libname}.spin2"
        COMMAND ${WINE} $<TARGET_FILE:s2pasm> -p "${CMAKE_CURRENT_LIST_DIR}/prefix.spin2" "${libname}.s"
        DEPENDS s2pasm "${CMAKE_CURRENT_BINARY_DIR}/${libname}.s"
    )
    add_custom_command(OUTPUT "${libname}.o" "${libname}.bin" "${libname}.lst"
        COMMAND ${WINE} $<TARGET_FILE:p2asm> -c -o -hub "${libname}.spin2"
        DEPENDS p2asm "${libname}.spin2"
    )
    add_custom_target(${libname} ALL DEPENDS "${libname}.o")
endfunction()

function(build_lib libname)
    foreach(source ${ARGN})
        get_filename_component(source_basename "${source}" NAME_WE)
        if (NOT TARGET ${source_basename})
            if (source MATCHES ".*\\.c")
                c2o(${source_basename})
            elseif (source MATCHES ".*\\.s")
                s2o(${source_basename} 1)
            else ()
                message(FATAL_ERROR "No rule to compile ${source}")
            endif ()
        endif ()
        list(APPEND OBJECT_FILES ${source_basename}.o)
    endforeach()
    add_custom_command(OUTPUT "${libname}.a"
        COMMAND "${PROPGCC_AR}" q "${libname}.a" ${OBJECT_FILES}
        DEPENDS ${OBJECT_FILES}
    )
    add_custom_target(${libname} ALL DEPENDS "${libname}.a")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${libname}.a" DESTINATION share/p2gcc/lib)
endfunction()

# stdio
set(STDIO_SOURCES
    fileio.c
    fprintf.c
    fsrw.c
    getchar.c
    gets.c
    printf.c
    putch.c
    putchar.c
    puts.c
    scanf.c
    sdspi.c
    sprintf.c
    sscanf.c
    getch.s
)
build_lib(stdio ${STDIO_SOURCES})

# stdlib
set(STDLIB_SOURCES
    atoi.c
    atol.c
    clock.c
    ctype.c
    malloc.c
    rand.c
    sleep.c
    strtol.c
    tolower.c
    toupper.c
    abort.s
    exit.s
)
build_lib(stdlib ${STDLIB_SOURCES})

# strlib
set(STRING_SOURCES
    memcpy.c
    memset.c
    strcat.c
    strcmp.c
    strcpy.c
    strncpy.c
    strlen.c
    strncmp.c
)
build_lib(string ${STRING_SOURCES})

c2o(libm)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/libm.o" DESTINATION share/p2gcc/lib RENAME libm.a)

build_lib(libc
    ${STDIO_SOURCES}
    ${STDLIB_SOURCES}
    ${STRING_SOURCES}
    # Some extra stuff for libc
    cogstart.c
    cogthread.c
    float.c
    longlong.c
)
