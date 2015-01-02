RecoveryKitchen
==============

Dual Recovery for Xperia devices

==============

Run 'dualrecovery' to start building. It is menu driven for ease of use.

Currently supported are:

* Sony Xperia Z
* Sony Xperia ZL
* Sony Xperia ZR
* Sony Xperia Tablet Z
* Sony Xperia Z Ultra
* Sony Xperia Z1
* Sony Xperia Z1 Compact
* Sony Xperia T/V/TX/TL
* Sony Xperia SP
* Sony Xperia Z2
* Sony Xperia Tablet Z2
* Sony Xperia T2 Ultra
* Sony Xperia Z3
* Sony Xperia Z3 Compact
* Sony Xperia Tablet Z3 Compact

The main device menu is split up in to 3 major parts, 'Build' and 'Recovery'.

The 'Recovery' choice allows you to compile the recoveries from source without breaking a sweat ;)
After building you can apply the 'private' patches. Make sure the patches are still compatible
with the newer built recoveries!

The 'LB Build' menu item has an 'all' option, which will allow you to grab the latest built and patched
without the compilation bits. It will also ask if you wish to increase the revision number and if
you wish to upload it... which obviously will only work if you have the correct password.

The 'Kernel Build' menu item has this all option as well. It can in theory repack any kernel but for now
only stock kernels are supported. Put the kernel inside kernels/{DEVICE}/ and name the kernel file
{MODEL}_{ROMVERSION}.sin for easy recognition by anyone. You can choose what kernel to repack with menu
option 1. 

==============

For now all releases will be officially done by [NUT] a.k.a. xNUTx.

If you wish to contribute to this project, contact [NUT] through XDA PM.
