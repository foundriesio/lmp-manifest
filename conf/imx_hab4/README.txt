===========
Documents:
===========

Feature Guide
      read <https://www.nxp.com/docs/en/application-note/AN4581.pdf>

Fuse Table:
     You will neeed the reference security manual for your SoC (it
     should contain the fuse table)
     
     In the case of the IMX7ULP, the fuses are
     	SRK:		bank 5  word [0 - 7]
	SEC_CONFIG[1]:  bank 29 word 6 [only bit 31]

Software:
	Download: NXP CST 3.1 to /tmp/cst_3.1
	Clone lmp-manifest
	      git clone https://github.com/foundriesio/lmp-manifest.git

===========================
Build, Sign and install SPL
===========================
1. Create a directory where SPL will be signed
$ mkdir /tmp/spl,sign

2. Copy the already generated tables (SRK and fuse) to the working directory
$ cp lmp-manifest/conf/imx_hab4/* /tmp/spl,sign/

3. Copy the code signing tool for your server architecture
$ cp /tmp/cst_3.1/linux64/bin/cst /tmp/spl,sign/

4. Use U-boot to fuse the SRK values on your board
Build U-boot: CONFIG_CMD_FUSE
Double check that the fuse table is correct

$ cd /tmp/spl,sign
$ hexdump -e '/4 "0x"' -e '/4 "%X""\n"' SRK_1_2_3_4_fuse.bin
0xEA2F0B50
0x871167F7
0xF5CECF5D
0x364727C3
0x8DD52832
0xF158F65F
0xA71BBE78
0xA3AD024A

From the U-boot console:
(not that on the imx7ulp SoC the fuse bank for the SRK is bank 5)
=> fuse prog 5 0 0xEA2F0B50
=> fuse prog 5 1 0x871167F7
=> fuse prog 5 2 0xF5CECF5D
=> fuse prog 5 3 0x364727C3
=> fuse prog 5 4 0x8DD52832
=> fuse prog 5 5 0xF158F65F
=> fuse prog 5 6 0xA71BBE78
=> fuse prog 5 7 0xA3AD024A

5. Build SPL with HAB support
Build U-Boot: CONFIG_IMX_HAB

When SPL is built:
$ cat SPL.log | grep HAB
HAB Blocks:   0x2f010400 0x00000000 0x00016c00

6. Then sign the SPL image
$ cp SPL /tmp/spl,sign
$ cd /tmp/spl,sign

Replace the commented out Blocks line at the bottom with the HAB blocks
information from the previous step
$ vi spl,sign/u-boot-spl-sign.csf-template

Use the Code Signing Tool binary to generate the signature
$ ./cst -o csf-spl.bin -i u-boot-spl-sign.csf-template

Now append the signature to the SPL image
$ cat SPL  csf-spl.bin > SPL.signed

7. Install this SPL.signed image via SDP (uuu bootloader.uuu)

8. Boot the image and check the HAB events for errors (no events is a pass!)
=> hab_status
Secure boot disabled
HAB Configuration: 0xf0, HAB State: 0x66
No HAB Events Found!

9. Close the device by burning SEC_CONFIG fuse
On imx7ulp SEC_CONFIG[1] is at bank 29, word 6.
Secure boot is enabled by setting bit 31

=> fuse prog 29 6 0x80000000

10. Reboot your board and check the HAB status

=> hab_status
Secure boot enabled
HAB Configuration: 0xcc, HAB State: 0x99
No HAB Events Found!

Upgrades via SDP after the device was closed
============================================
Once the device has been closed, only signed images will be able to
run on the processor.

Support for upgrade via the Serial Download Protocol using the MFG tools 
continues to be possible but with certain caveats. SDP requires that
the CSF is modified to check the DCD table; it also needs that the DCD
address in the signed image is cleared from the IVT header (since the
SDP protocol clears the DCD table address).

To handle both requirements, we will need to sign the SPL-mfg
differently than previously described.

Notice that in all cases HAB (high assurance boot) needs to be enabled
in the config. U-Boot on the MFG and the final target platform doesn't
need to be built any differently since it is not signed for HAB. 

===============
Signing SPL MFG 
===============
Use the following scripts to handle the DCD as previously described.
Once SPLMfg has been built, check the DCD address by

/tools/mkimage -l SPL

Image Type:   Freescale IMX Boot Image
Image Ver:    2 (i.MX53/6/7 compatible)
Mode:         DCD
Data Size:    147552 Bytes = 144.09 KiB = 0.14 MiB
Load Address: 2f010420
Entry Point:  2f011000
HAB Blocks:   0x2f010400 0x00000000 0x00021c00
DCD Blocks:   0x00910000 0x0000002c 0x00000258

Notice that the DCD address is hardcoded to a wrong address on some
u-boot versions; we sent a fix to the mainters to correct it since on
the imx7ulp this address should be 0x2f010000.

This information will be used to generate the Command Sequence File
(CSF) used to sign the image.

The Command Sequence File will need access to the SRK table amd PEM files.
You can get them as before from the lmp-manifest repo.

SPLMfg.csf
----------
[Header]
Version = 4.1
Security Configuration = Open
Hash Algorithm = sha256
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS
Engine = CAAM

[Install SRK]
File = "./SRK_1_2_3_4_table.bin"
Source index = 0

[Install CSFK]
File = "./CSF_1_crt.pem"

[Authenticate CSF]

[Install Key]
# Key slot index used to authenticate the key to be installed
Verification index = 0

# Key to install
Target index = 2
File = "./IMG_1_crt.pem"

[Authenticate Data]
Verification index = 2
Blocks = 0x2f010000 0x02c 0x00258 "./SPLmfg.bin"

[Authenticate Data]
Verification index = 2
Blocks = 0x2f010400 0x000 0x21c00 "./SPLmfg.bin"

To sign the SPLMfg image just copy the SPL image from U-boot, rename it to
SPLMfg.bin and execute the sign.spl.mfg.sh script

==============================
Boot a Signed SPLmfg using SDP
==============================
Make sure to use a version of the UUU tool that includes support for
the -dcdaddr and -cleardcd flags; these should be present in the next
mfgtools release following 1.3.102.

To boot the signed image via SDP:
SDP: boot -f SPL-aeler-imx7ulpea-ucom -dcdaddr 0x2f010000 -cleardcd  

It could be the case that UUU times out during this operation; this could be 
due to some watchdogs having been activated for the platform once the device 
was closed. If you experience this issue, you will need to rebuild UUU
applying the following  patch to increase the polling frequency.

diff --git a/libuuu/usbhotplug.cpp b/libuuu/usbhotplug.cpp
index d8f958c..4b524bb 100644
--- a/libuuu/usbhotplug.cpp
+++ b/libuuu/usbhotplug.cpp
@@ -153,7 +153,7 @@ static int usb_add(libusb_device *dev)
                return -1;

        ConfigItem *item = get_config()->find(desc.idVendor, desc.idProduct, desc.bcdDevice);
-   std::this_thread::sleep_for(std::chrono::milliseconds(200));
+ std::this_thread::sleep_for(std::chrono::milliseconds(1));

        if (item)
        {
@@ -245,7 +245,7 @@ int polling_usb(std::atomic<int>& bexit)

                oldlist = newlist;

-           std::this_thread::sleep_for(std::chrono::milliseconds(200));
+         std::this_thread::sleep_for(std::chrono::milliseconds(1));

                if (g_wait_usb_timeout >= 0 && !g_known_device_appeared)
                {

We submited a proposal [1] to be able to configure the usb polling
frequency dynamically; if it is present in your UUU release, then
use it as
$ uuu -pp 1 bootloader.uuu

[1] https://github.com/NXPmicro/mfgtools/pull/147
