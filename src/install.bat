@echo off
setlocal EnableDelayedExpansion

REM #####################
REM ## CHOICE CHECK
REM #####################
choice /T 0 /D Y /C Y /M test > nul 2>&1
if "!errorlevel!" == "1" (
	set CHOICE=choice
	set CHOICE_TEXT_PARAM=/M
) else (
	choice /T 0 /D Y /C Y test > nul 2>&1
	if "!errorlevel!" == "1" (
		set CHOICE=choice
		set CHOICE_TEXT_PARAM=
	) else (
		tools\choice32.exe /TY,1 /CY > nul 2>&1
		if "!errorlevel!" == "1" (
			set CHOICE=tools\choice32.exe
		) else (
			tools\choice32_alt.exe /T 0 /D Y /C Y /M test > nul 2>&1
			if "!errorlevel!" == "1" (
				set CHOICE=tools\choice32_alt.exe
				set CHOICE_TEXT_PARAM=/M
			) else (
				tools\choice64.exe /T 0 /D Y /C Y /M test > nul 2>&1
				if "!errorlevel!" == "1" (
					set CHOICE=tools\choice64.exe
					set CHOICE_TEXT_PARAM=/M
				)
			)
		)
	)
)

echo.
echo ==============================================
echo =                                            =
echo =  PhilZ Touch, CWM and TWRP Dual Recovery   =
echo =           Maintained by [NUT]              =
echo =                                            =
echo =       For Many Sony Xperia Devices!        =
echo =                                            =
echo ==============================================
echo.

cd files

set menu_currentIndex=1
set menu_choices=1

echo [ !menu_currentIndex!. Installation on ROM rooted with SuperSU ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Installation on ROM rooted with SuperUser ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Installation on unrooted ROM using TowelRoot ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Exit ]

%CHOICE% /c:!menu_choices! %CHOICE_TEXT_PARAM% "Please choose install action."

set menu_decision=%errorlevel%
set menu_currentIndex=
set menu_choices=

if "!menu_decision!" == "4" (
	goto abort
)

adb kill-server
adb start-server

echo =============================================
echo Waiting for Device, connect USB cable now...
echo =============================================
adb wait-for-device
echo Device found!
echo.

echo.
echo =============================================
echo Step2 : Sending the recovery files.
echo =============================================
adb shell "mkdir /data/local/tmp/recovery"
adb push dr.prop /data/local/tmp/recovery/dr.prop
adb push chargemon.sh /data/local/tmp/recovery/chargemon
adb push mr.sh /data/local/tmp/recovery/mr
adb push dualrecovery.sh /data/local/tmp/recovery/dualrecovery.sh
adb push NDRUtils.apk /data/local/tmp/recovery/NDRUtils.apk
adb push rickiller.sh /data/local/tmp/recovery/rickiller.sh
adb push disableric /data/local/tmp/recovery/disableric
adb push busybox /data/local/tmp/recovery/busybox
adb push recovery.twrp.cpio.lzma /data/local/tmp/recovery/recovery.twrp.cpio.lzma
adb push recovery.philz.cpio.lzma /data/local/tmp/recovery/recovery.philz.cpio.lzma
adb push recovery.cwm.cpio.lzma /data/local/tmp/recovery/recovery.cwm.cpio.lzma
if exist {ramdisk.stock.cpio.lzma} (
	adb push ramdisk.stock.cpio.lzma /data/local/tmp/recovery/ramdisk.stock.cpio.lzma
)
adb push installrecovery.sh /data/local/tmp/recovery/install.sh

echo.
echo =============================================
echo Step3 : Setup of dual recovery.
echo =============================================
adb shell "chmod 755 /data/local/tmp/recovery/install.sh"
adb shell "chmod 755 /data/local/tmp/recovery/busybox"

if "!menu_decision!" == "1" (
	echo Look at your device and grant supersu access!
	echo Press any key to continue AFTER granting root access.
	adb shell "/system/xbin/su -c /data/local/tmp/recovery/busybox ls -la /data/local/tmp/recovery/busybox"
	pause
	adb shell "su -c /data/local/tmp/recovery/install.sh"
	goto cleanup
)

if "!menu_decision!" == "2" (
	adb shell "su -c /data/local/tmp/recovery/install.sh"
	goto cleanup
)

if "!menu_decision!" == "3" (
	goto easyRootTool
)

:cleanup

adb wait-for-device
adb shell "/system/xbin/busybox rm -rf /data/local/tmp/*"
adb kill-server

echo.
echo =============================================
echo Installation finished. Enjoy the recoveries!
echo =============================================
echo.

pause
goto end

:abort
echo.
echo =============================================
echo            Installation aborted!
echo =============================================
echo.

pause
goto end

:easyRootTool

echo =============================================
echo Attempting to get root access for installation using TowelRoot now.
echo.
echo NOTE: this only works on certain ROM/Kernel versions!
echo.
echo If it fails, please check the development thread ^(Post #2^) on XDA for more details.
echo.
echo REMEMBER THIS:
echo.
echo XZDualRecovery does NOT install any superuser app!!
echo.
echo You can use one of the recoveries to root your device.
echo =============================================

echo.
echo =============================================
echo Getting ro.build.product
echo =============================================

set product_name=
for /f "delims=" %%i in ('adb shell "getprop ro.build.product"') do ( set product_name=%%i)
echo Device model is %product_name%
for /f "delims=" %%i in ('adb shell "getprop ro.build.id"') do ( set firmware=%%i)
echo Firmware is %firmware%

echo.
echo =============================================
echo Sending files
echo =============================================

set zxzFile=zxz.sh

for /f "delims=" %%i in ('adb shell "ls /dev/kmem"') do ( set kmem_exist=%%i )
if NOT "%kmem_exist%" == "/dev/kmem: No such file or directory " (
  set zxzFile=zxz_kmem.sh
  echo /dev/kmem exists. Using files of cubeundcube...
)

adb push easyroottool\%zxzFile% /data/local/tmp/zxz.sh
adb push easyroottool\writekmem /data/local/tmp/
adb push easyroottool\findricaddr /data/local/tmp/
adb shell "cp /data/local/tmp/recovery/busybox /data/local/tmp/"
adb shell "chmod 777 /data/local/tmp/busybox"
adb shell "chmod 777 /data/local/tmp/zxz.sh"
adb shell "chmod 777 /data/local/tmp/writekmem"
adb shell "chmod 777 /data/local/tmp/findricaddr"

if "%zxzFile%" == "zxz.sh" (
  echo.
  echo Copying kernel module...
  adb push easyroottool\kernelmodule_patch.sh /data/local/tmp/kernelmodule_patch.sh
  adb shell "chmod 777 /data/local/tmp/kernelmodule_patch.sh"
  adb shell "/data/local/tmp/kernelmodule_patch.sh"
)

echo.
echo =============================================
echo Loading geohot's towelroot ^(modified by zxz0O0^)
echo =============================================

adb uninstall com.geohot.towelroot
adb install easyroottool/tr_signed.apk

adb shell "am start -n com.geohot.towelroot/.TowelRoot" >nul 2>&1
echo =============================================
echo.
echo Check your phone and click "make it ra1n"
echo.
echo Waiting for towelroot to exploit...
:RootCheck
echo|set /p=.
ping 1.1.1.1 -n 1 -w 2000 > nul
adb wait-for-device
set isRooted=""
for /f "delims=" %%i in ('adb shell "su -c ls -l"') do (set isRooted=%%i)
if "%isRooted%" == "/system/bin/sh: su: not found" goto RootCheck
if "%isRooted%" == """" goto RootCheck
echo.
adb uninstall com.geohot.towelroot
adb shell "su -c /data/local/tmp/recovery/install.sh unrooted"
goto cleanup

:end
