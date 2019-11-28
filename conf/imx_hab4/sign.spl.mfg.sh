#!/bin/bash
PROG_NAME=SPLmfg

# DCD address must be cleared for signature, as mfgtool will clear it.
./mod_4_mfgtool.sh clear_dcd_addr SPLmfg.bin

# generate the signatures, certificates, ... in the CSF binary
./cst --o SPLmfg_csf.bin --i SPLmfg.csf

# DCD address must be set for mfgtool to localize the DCD table.
./mod_4_mfgtool.sh set_dcd_addr SPLmfg.bin

# gather ${PROG_NAME} + its CSF
cat SPLmfg.bin SPLmfg_csf.bin > SPLmfg_signed.bin
