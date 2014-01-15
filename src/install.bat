@echo off
setlocal EnableDelayedExpansion

if exist "%PROGRAMFILES(X86)%" (
	set CHOICE=choice64.exe
	set CHOICE_TEXT_PARAM=/m
) else (
	if "%PROCESSOR_ARCHITECTURE%" == "x86" (
		set CHOICE=choice32.exe
		set CHOICE_TEXT_PARAM=
	) else (
		set CHOICE=choice64.exe
		set CHOICE_TEXT_PARAM=/m
	)
)

echo.
echo ==============================================
echo =                                            =
echo =  PhilZ Touch, CWM and TWRP Dual Recovery   =
echo =          Maintained by [NUT]               =
echo =                                            =
echo = For Xperia Z, ZL, Z Ultra, Z1 and Tablet Z =
echo =                                            =
echo ==============================================
echo.
echo BIG thanks to DooMLoRD and krabappel2548
echo.

cd files

set menu_currentIndex=1
set menu_choices=1

echo [ !menu_currentIndex!. SuperSU ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. SuperUser ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Abort! ]

%CHOICE% /c:!menu_choices! %CHOICE_TEXT_PARAM% "Which root app do you use?"

set menu_decision=%errorlevel%
set menu_currentIndex=
set menu_choices=

if "!menu_decision!" == "3" (
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
	adb shell "/system/xbin/su -c /system/bin/ls -la /data/local/tmp/recovery/busybox"
	pause
)

adb shell "su -c /data/local/tmp/recovery/install.sh"

echo Waiting for your device to reconnect.
echo After entering CWM for the first time, reboot to system to complete this installer if you want it to clean up after itself.

adb wait-for-device

adb shell "rm -r /data/local/tmp/recovery"

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

:end
