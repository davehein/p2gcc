cmake_minimum_required(VERSION 3.0)

project(p2gcc VERSION 0.0.1)

option(BUILD_LIBS "Build p2gcc's libraries" ON)

add_compile_options(-Wall)

add_subdirectory(loadp2_src)

add_executable(p2asm p2asm_src/p2asm.c p2asm_src/symsubs.c p2asm_src/strsubs.c)
target_link_libraries(p2asm m)
install(TARGETS p2asm DESTINATION bin)

add_executable(p2link p2link_src/p2link.c)
install(TARGETS p2link DESTINATION bin)

add_executable(s2pasm s2pasm_src/s2pasm.c s2pasm_src/lmmsubs.c)
install(TARGETS s2pasm DESTINATION bin)

add_executable(p2dump util/p2dump.c)
install(TARGETS p2dump DESTINATION bin)

add_executable(p2dumpobj util/p2dumpobj.c)
install(TARGETS p2dumpobj DESTINATION bin)

if (BUILD_LIBS)
    add_subdirectory(lib)
endif ()

install(FILES
        bas.c
        blink.c
        chess.c
        dry.c
        fft_bench.c
        fibo.c
        filetest.c
        fsrwtest.c
        hello.c
        malloctest.c
        preshell.spin2
        prime.c
        shell.c
        start.c
        test7.c
        test8.c
        xxtea.c
        xxtea.h
    DESTINATION share/p2gcc/examples)
install(PROGRAMS util/diffit load_shell test_all DESTINATION bin)
if (WIN32)
    install(PROGRAMS p2gcc.bat DESTINATION bin)
else ()
    install(PROGRAMS p2gcc DESTINATION bin)
endif ()

include(./p2gccCPack.cmake)
