@echo off
setlocal EnableDelayedExpansion

cd files

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

set menu_currentIndex=1
set menu_choices=1

echo [ !menu_currentIndex!. Installation on ROM rooted with SuperSU ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Installation on ROM rooted with SuperUser ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Installation on unrooted ROM using the TowelRoot method ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Install ADB drivers to windows ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Exit ]

%CHOICE% /c:!menu_choices! %CHOICE_TEXT_PARAM% "Please choose install action."

set menu_decision=%errorlevel%
set menu_currentIndex=
set menu_choices=

if "!menu_decision!" == "5" (
	goto abort
)

adb kill-server
adb start-server

echo.
echo =============================================
echo Waiting for Device, connect USB cable now...
echo =============================================
adb wait-for-device
echo Device found!
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

if "!menu_decision!" == "4" (
	goto WinDriverSetup
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
echo Sending files
echo =============================================

adb push easyroottool\zxz.sh /data/local/tmp/zxz.sh
adb push easyroottool\towelzxperia /data/local/tmp/
adb push easyroottool\libexploit.so /data/local/tmp/
adb push easyroottool\writekmem /data/local/tmp/
adb push easyroottool\findricaddr /data/local/tmp/
adb shell "cp /data/local/tmp/recovery/busybox /data/local/tmp/"
adb shell "chmod 777 /data/local/tmp/busybox"
adb shell "chmod 777 /data/local/tmp/zxz.sh"
adb shell "chmod 777 /data/local/tmp/towelzxperia"
adb shell "chmod 777 /data/local/tmp/writekmem"
adb shell "chmod 777 /data/local/tmp/findricaddr"

echo Copying kernel module...
adb push easyroottool\wp_mod.ko /data/local/tmp/
adb push easyroottool\kernelmodule_patch.sh /data/local/tmp/
adb shell "chmod 777 /data/local/tmp/kernelmodule_patch.sh"
adb push easyroottool\modulecrcpatch /data/local/tmp/
adb shell "chmod 777 /data/local/tmp/modulecrcpatch"
adb shell "/data/local/tmp/kernelmodule_patch.sh"

echo.
echo =============================================
echo Installing using zxz0O0's towelzxperia
echo ^(using geohot's towelroot library^)
echo =============================================

adb shell "/data/local/tmp/towelzxperia /data/local/tmp/recovery/install.sh unrooted"
goto cleanup

:WinDriverSetup
echo.
echo =============================================
echo Connect your device while it is in any recovery now!
echo =============================================
echo.
pause
echo.
echo =============================================
echo Start installing adb driver. It's not signed,
echo but it's safe to install!
echo =============================================
echo.
RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 adbdrivers/android_winusb.inf
echo.
echo =============================================
echo            Installation finished!
echo =============================================
echo.
ping 1.1.1.1 -n 1 -w 2000 > nul
goto menu

:end
