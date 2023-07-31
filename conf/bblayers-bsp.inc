# These layers are all the BSP layers supported by default in LMP
#
# If you want to customize the default BSP layers in a factory,
# change bblayers-factory.inc instead.
#
BSPLAYERS = " \
  ${OEROOT}/layers/meta-arm/meta-arm \
  ${OEROOT}/layers/meta-arm/meta-arm-toolchain \
  ${OEROOT}/layers/meta-arm/meta-arm-bsp \
  ${OEROOT}/layers/meta-freescale \
  ${OEROOT}/layers/meta-freescale-3rdparty \
  ${OEROOT}/layers/meta-raspberrypi \
  ${OEROOT}/layers/meta-intel \
  ${OEROOT}/layers/meta-yocto/meta-yocto-bsp \
  ${OEROOT}/layers/meta-xilinx/meta-xilinx-core \
  ${OEROOT}/layers/meta-xilinx/meta-xilinx-bsp \
  ${OEROOT}/layers/meta-xilinx/meta-xilinx-standalone \
  ${OEROOT}/layers/meta-xilinx-tools \
  ${OEROOT}/layers/meta-tegra \
  ${OEROOT}/layers/meta-ti/meta-ti-bsp \
  ${OEROOT}/layers/meta-ti/meta-ti-extras \
  ${OEROOT}/layers/meta-st-stm32mp \
  ${OEROOT}/layers/meta-lmp/meta-lmp-bsp \
"

BBMASK:append = " /meta-lmp/meta-lmp-bsp/recipes-bsp/alsa/alsa-state-stm32mp1.bbappend"
BSPLAYERS:remove = "\
  ${OEROOT}/layers/meta-st-stm32mp \
"
