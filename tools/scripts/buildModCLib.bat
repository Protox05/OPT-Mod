:: This script will build the CLib mod. Per default this program pauses at the end of execution to let the user
:: inspect the output of the called commands
:: Param 0: Which version of the mod should be built. Possible values are [dev|release|both|ask] where ask has the same effect
:: 				as omitting this parameter: There will be an interactive prompt asking for any of the other three values
:: Param 1: If this value is either noPause or buildModAll, the script won't pause at the end of execution

@echo off

:: This batch file will set the pboName variable
call .\getPBOName.bat ..\..\dependencies\CLib\addons\CLib\pboName.h clib

set version=%1

if [%version%] == [ask] (
	set "version="
	goto :askForVersion
)
if [%version%] == [] goto :askForVersion
::else
goto processArgs


:askForVersion
	:: If this script is being called without arguments, ask what to do
	set /P version="Which version of the CLib mod do you want to build (dev/release/both - default: dev)? "

	
:processArgs
	if [%version%] == [] set version=dev
	if [%version%] == [dev] goto dev
	if [%version%] == [stable] set version=release
	if [%version%] == [release] goto release
	if [%version%] == [both] goto release

	:: if this code is executed it means that an invalid option has been used
	echo Unknown version %version% - falling back to building dev version%
	set version=dev
	goto dev


:release
	:: build release
	call .\createModDir.bat CLib release
	
	echo Building release version of CLib Mod...
	
	:: move away all old PBOs
	for /f %%a IN ('dir ..\..\PBOs\release\@CLib\addons\ /b') do move ..\..\PBOs\release\@CLib\addons\%%a ..\..\PBOs\archive\release\ >nul
	
	..\programs\armake2.exe build  ..\..\dependencies\CLib\addons\CLib ..\..\PBOs\release\@CLib\addons\%pboName%

if not [%version%] == [both] goto finish


:dev
	:: build dev
	call .\createModDir.bat CLib dev
	
	echo Building dev version of the CLib Mod...
	
	:: move away all old PBOs
	for /f %%a IN ('dir ..\..\PBOs\dev\@CLib\addons\ /b') do move ..\..\PBOs\dev\@CLib\addons\%%a ..\..\PBOs\archive\dev\ >nul
	
	:: in order to build the dev-version the ISDEV macro flag has to be set programmatically
	1>NUL copy ..\..\dependencies\CLib\addons\CLib\isDev.hpp ..\..\dependencies\CLib\addons\CLib\isDev.hpp.original
	echo:>> ..\..\dependencies\CLib\addons\CLib\isDev.hpp
	echo|set /p="#define ISDEV" >> ..\..\dependencies\CLib\addons\CLib\isDev.hpp

	..\programs\armake2.exe build -x isDev.hpp.original ..\..\dependencies\CLib\addons\CLib\ ..\..\PBOs\dev\@CLib\addons\%pboName%
	
	::restore the isDev.hpp file
	del ..\..\dependencies\CLib\addons\CLib\isDev.hpp /q
	1>NUL copy ..\..\dependencies\CLib\addons\CLib\isDev.hpp.original ..\..\dependencies\CLib\addons\CLib\isDev.hpp
	del ..\..\dependencies\CLib\addons\CLib\isDev.hpp.original /q

:finish
	:: if this script hasn't been called from the build-all script and it hasn't been requested not to,
	:: issue a pause so the user can have a look at the output of the called commands
	if not [%2] == [buildModAll] (
		if not [%2] == [noPause] pause
	)