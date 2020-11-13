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
  ${OEROOT}/layers/meta-riscv \
  ${OEROOT}/layers/meta-rtlwifi \
  ${OEROOT}/layers/meta-intel \
  ${OEROOT}/layers/meta-yocto/meta-yocto-bsp \
  ${OEROOT}/layers/meta-xilinx/meta-xilinx-bsp \
  ${OEROOT}/layers/meta-xilinx-tools \
  ${OEROOT}/layers/meta-lmp/meta-lmp-bsp \
"

# Remove layer dependencies that are not used/required by LMP
## LMP provides its own kernel recipes
LAYERDEPENDS_meta-arm-bsp_remove = "meta-kernel"
