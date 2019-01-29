@echo off

if not -%1-==-- goto :nohelp
echo p2gcc - a C compiler for the propeller 2 - version 0.003, 2019-1-29
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
echo   -o file - Set output file name
echo   -p port - Port used for loading
goto :eof
:nohelp

set binfile=a.out
set verbose=0
set runflag=0
set simflag=0
set keepflag=0
set linkflag=0
set ccstr=propeller-elf-gcc -mcog -Os -S
set s2pasmstr=s2pasm
set asmstr=p2asm
set linkstr=p2link -L %P2GCC_LIBDIR% prefix.o p2gcc_start.o
set loadstr=loadp2
set simstr=spinsim

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
if %verbose% equ 1 echo %ccstr% %name%.c
%ccstr% %NAME%.c
if %ERRORLEVEL% neq 0 goto :eof
exit /b

:runs2pasm
if %verbose% equ 1 echo %s2pasmstr% -g -t -p%P2GCC_LIBDIR%\prefix.spin2 %name%
%s2pasmstr% -g -t -p%P2GCC_LIBDIR%\prefix.spin2 %name%
if %ERRORLEVEL% neq 0 goto :eof
exit /b

:runp2asm
if %verbose% equ 1 echo %asmstr% -o -hub %name%.spin2
%asmstr% -o -hub %name%.spin2
if %ERRORLEVEL% neq 0 goto :eof
set linkstr=%linkstr% %NAME%.o
exit /b

