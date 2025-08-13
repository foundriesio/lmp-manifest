# These layers are all the BSP layers supported by default in LMP
#
# If you want to customize the default BSP layers in a factory,
# change bblayers-factory.inc instead.
#
BSPLAYERS = " \
  ${OEROOT}/layers/meta-qcom \
  ${OEROOT}/layers/meta-arm/meta-arm \
  ${OEROOT}/layers/meta-arm/meta-arm-toolchain \
  ${OEROOT}/layers/meta-intel \
  ${OEROOT}/layers/meta-lmp/meta-lmp-bsp \
"
