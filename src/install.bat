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

echo [ !menu_currentIndex!. Installation on unrooted ROM using the vold exploit by Sacha and GranPC ]

set /a menu_currentIndex+=1 >nul
set menu_choices=!menu_choices!!menu_currentIndex!

echo [ !menu_currentIndex!. Installation on unrooted ROM using rootkitXperia by cubeundcube ]

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
if "!menu_decision!" == "3" (
	adb push getroot /data/local/tmp/recovery/getroot
)
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
)

if "!menu_decision!" == "1" (
	adb shell "su -c /data/local/tmp/recovery/install.sh"
)

if "!menu_decision!" == "2" (
	adb shell "su -c /data/local/tmp/recovery/install.sh"
)

if "!menu_decision!" == "3" (
	echo =============================================
	echo Attempting to get root access for installation using the vold exploit now.
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

	adb install sacha-granpc/exploit/exploit.apk

	# Now let us copy the scripts
	echo "Copying files.."
	adb push sacha-granpc/scripts/ /data/local/tmp/recovery/
	adb shell chmod 777 /data/local/tmp/recovery/
	adb shell /data/local/tmp/recovery/vdcCreate
	adb shell /data/local/tmp/recovery/startService

	echo -e "\n\n --- Attention ---\nPlease 'crash' the Service Menu app that pops up."
	echo "For example: Service Info -> Configuration."

	# Will only continue if SELinux is disabled.
	:checkselinux
		adb shell "if [ ^`getenforce^` = "Permissive" ]; then touch /data/local/tmp/selinux; fi"
		adb pull /data/local/tmp/selinux
		if NOT exist {selinux} (
			ping 1.0.0.0 -n 1 -w 2000 >NUL
			GOTO checkselinux
		)
	
	echo "Congratulations, SELinux is dead. Continuing.."
	adb shell 'vdc asec mount ../../data/local/tmp/vlib none 2000'
	adb shell /data/local/tmp/recovery/startService

	echo -e "\n\n --- Attention ---\nPlease 'crash' the Service Menu app that pops up."
	echo "For example: Service Info -> Configuration."

	# Will only continue if installation has finished
	:checkinstall
		adb pull /data/local/tmp/xzdrinstalled
		if NOT exist {xzdrinstalled} (
			ping 1.0.0.0 -n 1 -w 2000 >NUL
			GOTO checkinstall
		)

	adb uninstall com.peniscorp.bobsgamecontrols

	echo "Congratulations, it worked! Your device should now reboot."
	
)

if "!menu_decision!" == "4" (
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

	adb shell "chmod 755 /data/local/tmp/recovery/getroot"
	adb shell "/data/local/tmp/recovery/getroot /data/local/tmp/recovery/install.sh"
)

adb wait-for-device
adb shell "rm -r /data/local/tmp/selinux"
adb shell "rm -r /data/local/tmp/xzdrinstalled"
adb shell "rm -rf /data/local/tmp/recovery"
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
