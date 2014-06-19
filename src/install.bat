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
adb shell "rm -rf /data/local/tmp/*"
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

if exist easyroottool\tr_signed.apk goto SkipPatch
if exist easyroottool\tr.apk goto DoPatch

echo.
if not exist easyroottool\tr.apk (
	echo =============================================
	echo Downloading tr.apk, please allow curl.exe
	echo access through your firewall if downloading
	echo fails.
	echo =============================================
	easyroottool\curl.exe http://towelroot.com/tr.apk -o easyroottool\tr.apk
)

if exist easyroottool\tr.apk goto DoPatch

echo =============================================
echo Error downloading tr.apk with curl
echo Please place tr.apk inside the folder /files/easyroottool
echo and press any key to continue
echo You can download tr.apk from http://towelroot.com/
echo =============================================
pause
echo.
if not exist easyroottool\tr.apk (
	echo Error: easyroottool\tr.apk not found. Aborting...
	goto abort
)

:DoPatch

echo =============================================
echo Patching tr.apk and creating tr_signed.apk
echo =============================================
easyroottool\bspatch.exe easyroottool\tr.apk easyroottool\tr_signed.apk easyroottool\tr.apk.patch
if not exist easyroottool\tr_signed.apk (
	echo Error patching tr.apk. Aborting...
	goto abort
)
set tr_md5=
for /f "delims=" %%i in ('easyroottool\md5.exe easyroottool\tr_signed.apk') do ( set tr_md5=%%i )
if "%tr_md5%" == "D83363748CB1DCED97CC630419F8D587  easyroottool\tr_signed.apk " (
	echo OK!
) else (
	echo Error patching tr.apk. MD5 does not match. Aborting...
	echo Current MD5 is "%tr_md5%"
	echo.
	del easyroottool\tr_signed.apk
	goto abort
)
echo.

:SkipPatch

echo.
echo =============================================
echo Getting ro.build.product
echo =============================================

set product_name=
for /f "delims=" %%i in ('adb shell "getprop ro.build.product"') do ( set product_name=%%i )
echo Device model is %product_name%

echo.
echo =============================================
echo Sending files
echo =============================================

set zxzFile=zxz.sh
if "%product_name%" == "D6502 " (
	set zxzFile=zxz_z2.sh
)
if "%product_name%" == "D6503 " (
	set zxzFile=zxz_z2.sh
)
if "%product_name%" == "D6506 " (
	set zxzFile=zxz_z2.sh
)
if "%product_name%" == "D6543 " (
	set zxzFile=zxz_z2.sh
)
if "%product_name%" == "SGP511 " (
	set zxzFile=zxz_z2.sh
)
if "%product_name%" == "SGP512 " (
	set zxzFile=zxz_z2.sh
)
if "%product_name%" == "SGP521 " (
	set zxzFile=zxz_z2.sh
)
if "%zxzFile%" == "zxz_z2.sh" (
	echo Using Z2 files...
)

adb push easyroottool\%zxzFile% /data/local/tmp/zxz.sh
adb push easyroottool\writekmem /data/local/tmp/
adb push easyroottool\findricaddr /data/local/tmp/
adb shell "cp /data/local/tmp/recovery/busybox /data/local/tmp/"
adb shell "chmod 777 /data/local/tmp/busybox"
adb shell "chmod 777 /data/local/tmp/zxz.sh"
adb shell "chmod 777 /data/local/tmp/writekmem"
adb shell "chmod 777 /data/local/tmp/findricaddr"

echo.
echo =============================================
echo Loading modified towelroot ^(by geohot^)
echo =============================================

adb uninstall com.geohot.towelroot
adb install easyroottool\tr_signed.apk

adb shell "am start -n com.geohot.towelroot/.TowelRoot" >nul 2>&1
echo =============================================
echo Check your phone and click "make it ra1n"
echo.
echo ATTENTION: Press any key when the phone is DONE rebooting
echo.
pause
adb wait-for-device
adb uninstall com.geohot.towelroot
adb shell "su -c /data/local/tmp/recovery/install.sh"
goto cleanup

:end
