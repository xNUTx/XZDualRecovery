@echo off
cd files

:menu
cls
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

echo 1. Installation on ROM rooted with SuperSU
echo 2. Installation on ROM rooted with SuperUser
echo 3. Installation on an unrooted ^(Lollipop 5.0^) ROM using rootkitXperia
echo 4. Install ADB drivers to windows
echo 5. Exit
echo.
echo Please choose install action.
set /P C=[1,2,3,4,5]?

if "%C%" == "5" (
	goto abort
)
if "%C%" == "4" (
	goto WinDriverSetup
)

if "%C%" LSS "5" (
	goto install
)
cls
echo %C% is not a valid menu choice
goto menu

:install
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
adb push byeselinux\byeselinux.ko /data/local/tmp/recovery/byeselinux.ko
adb push byeselinux\byeselinux.sh /data/local/tmp/recovery/byeselinux.sh
adb push byeselinux\wp_mod.ko /data/local/tmp/recovery/wp_mod.ko
adb push byeselinux\sysrw.sh /data/local/tmp/recovery/sysrw.sh
adb push byeselinux\modulecrcpatch /data/local/tmp/recovery/modulecrcpatch
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

if "%C%" == "1" (
	echo Look at your device and grant supersu access!
	echo Press any key to continue AFTER granting root access.
	adb shell "/system/xbin/su -c /data/local/tmp/recovery/busybox ls -la /data/local/tmp/recovery/busybox"
	pause
	adb shell "su -c /data/local/tmp/recovery/install.sh"
	goto cleanup
)

if "%C%" == "2" (
	adb shell "su -c /data/local/tmp/recovery/install.sh"
	goto cleanup
)

if "%C%" == "3" (
	goto rootkitxperia
)

:cleanup

adb wait-for-device
adb shell "/system/bin/rm -rf /data/local/tmp/recovery"

set install_status=
for /f "delims=" %%i in ('adb shell "/system/bin/ls -1 /system/bin/dualrecovery.sh"') do ( set install_status=%%i)

if NOT "%install_status%" == "" (
	echo.
	echo =============================================
	echo Installation finished. Enjoy the recoveries!
	echo =============================================
	echo.
) else (
	echo.
	echo =============================================
	echo             Installation FAILED!
	echo.
	echo Please copy and paste the contents of this
	echo window to the DevDB thread for troubleshooting!
	echo =============================================
	echo.
)

adb kill-server
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

:rootkitxperia

echo =============================================
echo Attempting to get root access for installation using rootkitXperia now.
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

pause

echo.
echo =============================================
echo Sending files
echo =============================================

adb push rootkitxperia\getroot /data/local/tmp/recovery/getroot
adb shell "chmod 777 /data/local/tmp/recovery/getroot"

echo.
echo =============================================
echo Installing using cubeundcube's rootkitXperia
echo. 
echo Thanks to anyone involved in the development of this exploit:
echo. 
echo Keen Team, cubeundcube, AndroPlus and zxz0O0
echo =============================================

adb shell "/data/local/tmp/recovery/getroot /data/local/tmp/recovery/install.sh unrooted"
goto cleanup

:WinDriverSetup
echo.
echo =============================================
echo Connect your device while it is in any recovery now!
echo =============================================
echo.
echo Open the windows device manager, look up the device with an exclamation mark.
echo Right click on it and choose 'update driver'. You will want to locate
echo a driver on your disk and for that purpose point the installation wizard
echo to lockeddualrecovery\files\adbdrivers and install the driver there.
echo.
echo =============================================
echo IMPORTANT NOTE:
echo It's not signed, but it's safe to install!
echo =============================================
echo.
adb wait-for-device
echo =============================================
echo            Installation finished!
echo =============================================
echo.
pause
goto menu

:end
cd ..
