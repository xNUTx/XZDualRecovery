@echo off
cd files

:menu
cls
echo.
echo ==============================================
echo =                                            =
echo =              XZDualRecovery                =
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
adb push ..\tmp\dr.prop /data/local/tmp/recovery/dr.prop
adb push ..\system\bin\chargemon /data/local/tmp/recovery/chargemon
adb push ..\system\bin\mr /data/local/tmp/recovery/mr
adb push ..\system\.XZDualRecovery\xbin\dualrecovery.sh /data/local/tmp/recovery/dualrecovery.sh
adb push ..\tmp\NDRUtils.apk /data/local/tmp/recovery/NDRUtils.apk
adb push ..\system\.XZDualRecovery\xbin\rickiller.sh /data/local/tmp/recovery/rickiller.sh
adb push ..\tmp\byeselinux.ko /data/local/tmp/recovery/byeselinux.ko
adb push byeselinux\byeselinux.sh /data/local/tmp/recovery/byeselinux.sh
adb push ..\tmp\wp_mod.ko /data/local/tmp/recovery/wp_mod.ko
adb push byeselinux\sysrw.sh /data/local/tmp/recovery/sysrw.sh
adb push ..\tmp\modulecrcpatch /data/local/tmp/recovery/modulecrcpatch
adb push ..\system\.XZDualRecovery\xbin\busybox /data/local/tmp/recovery/busybox
adb push ..\system\.XZDualRecovery\xbin\recovery.twrp.cpio.lzma /data/local/tmp/recovery/recovery.twrp.cpio.lzma
adb push ..\system\.XZDualRecovery\xbin\recovery.philz.cpio.lzma /data/local/tmp/recovery/recovery.philz.cpio.lzma
if exist {..\system\.XZDualRecovery\xbin\ramdisk.stock.cpio.lzma} (
	adb push ..\system\.XZDualRecovery\xbin\ramdisk.stock.cpio.lzma /data/local/tmp/recovery/ramdisk.stock.cpio.lzma
)
adb push ..\tmp\installrecovery.sh /data/local/tmp/recovery/install.sh

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
for /f "delims=" %%i in ('adb shell "/system/bin/ls -1 /system/.XZDualRecovery/xbin/dualrecovery.sh"') do ( set install_status=%%i)

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
echo If it fails, please check the development thread ^(Post #2^) on 
echo XDA for more details.
echo.
echo.
echo ******** REMEMBER THIS: ********
echo.
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

:retryrootkitxperia

echo.
echo =============================================
echo Installing using cubeundcube's rootkitXperia
echo. 
echo Thanks to anyone involved in the development of this exploit:
echo. 
echo Keen Team, cubeundcube, AndroPlus and zxz0O0
echo =============================================

adb shell "/data/local/tmp/recovery/getroot "/data/local/tmp/recovery/install.sh unrooted""

ping 127.0.0.1 -n 11 > nul

echo.
echo =============================================
echo If your device now boots to recovery, reboot 
echo it to system to continue and allow this script
echo to check and clean up. The script will continue
echo once your device allows adb connections again.
echo =============================================
echo.

adb kill-server
adb start-server
adb wait-for-device

set install_status=
for /f "delims=" %%i in ('adb shell "/system/bin/ls -1 /system/.XZDualRecovery/xbin/dualrecovery.sh"') do ( set install_status=%%i)

if NOT "%install_status%" == "" (
	echo Unrooted installation was succesful!
	goto cleanup
) else (
	goto unrootmenu
)

:unrootmenu

echo. 
echo =============================================
echo Unrooted installation failed, please press 1 
echo once the device finished rebooting to retry.
echo. 
echo 1. Retry installation on an unrooted ROM using rootkitXperia
echo 2. Exit
echo.
echo =============================================
set /P C=[1,2]?

if "%C%" == "2" (
goto abort
)

if "%C%" == "1" (
goto retryrootkitxperia
)

cls
echo %C% is not a valid menu choice
goto unrootmenu

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
