# These layers are the basic and required layers by LMP
#
# Only change if you really know what you are doing.
#
BASELAYERS = " \
  ${OEROOT}/layers/meta-openembedded/meta-oe \
  ${OEROOT}/layers/meta-openembedded/meta-networking \
  ${OEROOT}/layers/meta-openembedded/meta-filesystems \
  ${OEROOT}/layers/meta-openembedded/meta-perl \
  ${OEROOT}/layers/meta-openembedded/meta-python \
  ${OEROOT}/layers/meta-virtualization \
  ${OEROOT}/layers/meta-clang \
  ${OEROOT}/layers/meta-updater \
  ${OEROOT}/layers/meta-security \
  ${OEROOT}/layers/meta-security/meta-tpm \
  ${OEROOT}/layers/meta-security/meta-parsec \
  ${OEROOT}/layers/meta-security/meta-integrity \
"
