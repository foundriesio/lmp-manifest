Linux microPlatform Manifest
============================

Foundries.io Linux microPlatform manifest.

This directory contains a Repo manifest and setup scripts for the
Linux microPlatform (LmP) build system. If you want to modify, extend or port
the LmP to a new hardware platform, this is the manifest repository to use.

The build system uses various components from the Yocto Project, most
importantly the OpenEmbedded build system, the bitbake task executor, and
various application and BSP layers.

To configure the scripts and download the build metadata, do:

```
mkdir ~/bin
PATH=~/bin:$PATH

curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

Run `repo init` to bring down the latest stable version of Repo. You must
specify a URL for the manifest, which specifies the various repositories that
will be placed within your working directory.

To check out the latest LmP subscriber continuous release:

```
repo init -u https://github.com/foundriesio/lmp-manifest
```

A successful initialization will end with a message stating that Repo
is initialized in your working directory. Your client directory should
now contain a `.repo/` directory where files such as the manifest will be kept.

To pull down the metadata sources to your working directory from the
repositories as specified in the LmP manifest, run:

```
repo sync
```

When downloading from behind a proxy (which is common in some
corporate environments), it might be necessary to explicitly specify the proxy
that is then used by repo:

```
export HTTP_PROXY=http://<proxy_user_id>:<proxy_password>@<proxy_server>:<proxy_port>
export HTTPS_PROXY=http://<proxy_user_id>:<proxy_password>@<proxy_server>:<proxy_port>
```

More rarely, Linux clients experience connectivity issues, getting stuck in the
middle of downloads (typically during "Receiving objects"). Tweaking the
settings of the TCP/IP stack and using non-parallel commands can improve the
situation. You need root access to modify the TCP setting:

```
sudo sysctl -w net.ipv4.tcp_window_scaling=0
repo sync -j1
```

Setup Environment
-----------------

Supported **MACHINE** targets (officially tested by Foundries):

* am62xx-evm
* am64xx-evm
* apalis-imx6
* apalis-imx6-sec
* apalis-imx8
* apalis-imx8-sec
* beaglebone-yocto
* generic-arm64
* imx6ulevk
* imx6ullevk
* imx6ullevk-sec
* imx7ulpea-ucom
* imx8mm-lpddr4-evk
* imx8mm-lpddr4-evk-sec
* imx8mn-ddr4-evk
* imx8mn-ddr4-evk-sec
* imx8mp-lpddr4-evk
* imx8mp-lpddr4-evk-sec
* imx8mq-evk
* imx8qm-mek
* imx8qm-mek-sec
* imx8ulp-lpddr4-evk
* imx93-11x11-lpddr4x-evk
* intel-corei7-64
* jetson-agx-orin-devkit
* jetson-agx-xavier-devkit
* qemuarm
* qemuarm64-secureboot
* qemuriscv64
* raspberrypi4-64
* stm32mp15-disco
* stm32mp15-eval
* stm32mp15-eval-sec
* kv260
* vck190-versal
* uz3eg-iocc
* uz3eg-iocc-sec

Supported image targets:

* lmp-mini-image          - minimal OSTree + OTA capable image
* lmp-base-console-image  - mini-image + Docker container runtime
* lmp-gateway-image       - base-console-image + edge gateway related utilities
* lmp-factory-image       - default (and only available) for a FoundriesFactory
* mfgtool-files           - (**only for DISTRO=lmp-mfgtool**) image flasher via
                            USB SDP/FastBoot for i.MX-based machines

The default distribution (DISTRO) variable is automatically set to `lmp`,
which is provided by the `meta-lmp` layer.

Setup the work environment by using the `setup-environment` script:

```
[MACHINE=<MACHINE>] source setup-environment [BUILDDIR]
```

If **MACHINE** is not provided, the script will list all possible machines and
force one to be selected.

To build the LmP base console image:

```
bitbake lmp-base-console-image
```

Issues and Support
------------------

Please report any bugs, issues or suggestions at <https://support.foundries.io>.
