@echo off

if not -%1-==-- goto :nohelp
echo p2gcc - a C compiler for the propeller 2 - version 0.006, 2019-02-12
echo usage: p2gcc [options] file [file...]
echo   options are
echo   -c      - Do not run the linker
echo   -v      - Enable verbose mode
echo   -d      - Enable debug mode
echo   -r      - Run after linking
echo   -t      - Run terminal emulator
echo   -T      - Run terminal emulator in PST mode
echo   -k      - Keep intermediate files
echo   -s      - Run simulator
echo   -LMM    - Generate LMM assembly
echo   -o file - Set output file name
echo   -p port - Port used for loading
echo   -D name - Pass a name to the compiler
echo   -L dir  - Specify a library directory
echo   -I dir  - Specify an include directory
echo   -b baud - Specify a user baud rate
echo   -f freq - Specify a clock frequency
goto :eof
:nohelp

set binfile=a.out
set verbose=0
set runflag=0
set simflag=0
set keepflag=0
set linkflag=0
set ccstr=propeller-elf-gcc -Os -S -D __P2GCC__
set s2pasmstr=s2pasm
set asmstr=p2asm
set linkstr=p2link -L %P2GCC_LIBDIR% prefix.o p2start.o
set loadstr=loadp2 -PATCH
set simstr=spinsim
set modelstr=-mcog
set s2pmodstr=

:argactionstart
if -%1-==-- goto argactionend

REM Process option flags
if not %1==-r goto :label20
  if %simflag% equ 1 goto :label31
  set runflag=1
  goto :nextparm
:label20
if not %1==-v goto :label21
  set verbose=1
  set loadstr=%loadstr% -v
  set linkstr=%linkstr% -v
  goto :nextparm
:label21
if not %1==-d goto :label22
  set verbose=1
  set debugmode=1
  set s2pasmstr=%s2pasmstr% -d
  set asmstr=%asmstr% -d
  set linkstr=%linkstr% -d
  set loadstr=%loadstr% -v
  goto :nextparm
:label22
if not %1==-t goto :label23
  set loadstr=%loadstr% -t
  goto :nextparm
:label23
if not %1==-T goto :label24
  set loadstr=%loadstr% -T
  goto :nextparm
:label24
if not %1==-k goto :label25
  set keepflag=1
  goto :nextparm
:label25
if not %1==-c goto :label26
  set linkflag=0
  goto :nextparm
:label26
if not %1==-o goto :label27
  shift
  set binfile=%1
  set linkstr=%linkstr% -o %1
  goto :nextparm
:label27
if not %1==-p goto :label32
  shift
  set loadstr=%loadstr% -p %1
  goto :nextparm
:label32
if not %1==-s goto :label30
  if %runflag% equ 1 goto :label31
  set simflag=1
  goto :nextparm
:label30
if not %1==-LMM goto :label33
  set modelstr=-mlmm -mno-fcache
  set s2pmodstr=-lmm
  goto :nextparm
:label33
if not %1==-D goto :label35
  shift
  set ccstr=%ccstr% -D %1
  goto :nextparm
:label35
if not %1==-L goto :label36
  shift
  set linkstr=%linkstr% -L %1
  goto :nextparm
:label36
if not %1==-I goto :label37
  shift
  set ccstr=%ccstr% -I %1
  goto :nextparm
:label37
if not %1==-b goto :label38
  shift
  set loadstr=%loadstr% -b %1
  goto :nextparm
:label38
if not %1==-f goto :label39
  shift
  set loadstr=%loadstr% -f %1
  goto :nextparm
:label39

REM Get the file name root and extension
set myvar=%1
set strippedvar=%myvar%
for /f "delims=." %%a in ("%strippedvar%") do set NAME=%%a
set prestrippedvar=%strippedvar%
set strippedvar=%strippedvar:*.=%
if not "%prestrippedvar:.=%"=="%prestrippedvar%" goto :label28
set EXTENSION=NULL
goto :label29
:label28
for /f "delims=." %%a in ("%strippedvar%") do set EXTENSION=%%a
:label29

REM Process file
if not %EXTENSION%==c goto :label10
  call :runpropgcc
  call :runs2pasm
  call :runp2asm
  if %keepflag% neq 1 del %name%.s %name%.spin2 %name%.lst %name%.bin
  set linkflag=1
  goto :nextparm
:label10
if not %EXTENSION%==s goto :label11
  call :runs2pasm
  call :runp2asm
  if %keepflag% neq 1 del %name%.spin2 %name%.lst %name%.bin
  set linkflag=1
  goto :nextparm
:label11
if not %EXTENSION%==spin2 goto :label12
  call :runp2asm
  if %keepflag% neq 1 del %name%.lst %name%.bin
  set linkflag=1
  goto :nextparm
:label12
if not %EXTENSION%==o goto :label13
  set linkstr=%linkstr% %NAME%.o
  set linkflag=1
  goto :nextparm
:label13
if not %EXTENSION%==a goto :label34
  set linkstr=%linkstr% %NAME%.a
  set linkflag=1
  goto :nextparm
:label34
  echo invalid extension in %1
  goto :eof
:label31
  echo Can't run simulator and hardware at the same time
  goto :eof

:nextparm
shift
goto argactionstart
:argactionend

if %linkflag% neq 1 goto :checksim
if %verbose% equ 1 echo %linkstr% libc.a
%linkstr% libc.a
if %ERRORLEVEL% neq 0 goto :eof

:checksim
if %simflag% neq 1 goto :checkrun
if %verbose% equ 1 echo %simstr% %binfile%
%simstr% %binfile%
exit /b

:checkrun
if %runflag% neq 1 goto :eof
if %verbose% equ 1 echo %loadstr% %binfile%
%loadstr% %binfile%
exit /b

:runpropgcc
if %verbose% equ 1 echo %ccstr% %modelstr% %name%.c
%ccstr% %modelstr% %NAME%.c
if %ERRORLEVEL% neq 0 goto :eof
exit /b

:runs2pasm
if %verbose% equ 1 echo %s2pasmstr% -p%P2GCC_LIBDIR%\prefix.spin2 %s2pmodstr% %name%
%s2pasmstr% -p%P2GCC_LIBDIR%\prefix.spin2 %s2pmodstr% %name%
if %ERRORLEVEL% neq 0 goto :eof
exit /b

:runp2asm
if %verbose% equ 1 echo %asmstr% -o -hub %name%.spin2
%asmstr% -o -hub %name%.spin2
if %ERRORLEVEL% neq 0 goto :eof
set linkstr=%linkstr% %NAME%.o
exit /b

