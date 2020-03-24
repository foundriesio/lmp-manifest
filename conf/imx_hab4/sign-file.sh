#!/bin/sh
#
# Copyright (c) 2019 Foundries.io
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# stop on errors
set -e

CST_BINARY="cst"
CSF_TEMPLATE="u-boot-spl-sign.csf-template"
KEY_DIR="."
DCD_CLEAR=0
DISPLAY_USAGE=0
SIGN_SPL=0
SIGN_M4APP=0

parse_args()
{
    while [ ${#} -gt 0 ]
    do
        case ${1} in
        --cst)
            CST_BINARY=${2}
            shift
            shift
            ;;
        --csf-template)
            CSF_TEMPLATE=${2}
            shift
            shift
            ;;
        --spl)
            WORK_FILE=${2}
            SIGN_SPL=1
            shift
            shift
            ;;
        --m4app)
            WORK_FILE=${2}
            SIGN_M4APP=1
            shift
            shift
            ;;
        --key-dir)
            KEY_DIR=${2}
            shift
            shift
            ;;
        --fix-sdp-dcd)
            DCD_CLEAR=1
            shift
            ;;
        -h)
            DISPLAY_USAGE=1
            shift
            ;;
        --help)
            DISPLAY_USAGE=1
            shift
            ;;
        *)
            shift
            ;;
        esac
    done
}

parse_args "$@"

if [ "${DISPLAY_USAGE}" = "1" ]; then
    echo "usage for: ${0}"
    echo "  --cst: set cst binary path/filename   [default: ${CST_BINARY}]"
    echo "  --csf-template: set CSF template file [default: ${CSF_TEMPLATE}]"
    echo "  --spl: SPL binary to sign             [--spl or --m4app is required]"
    echo "  --m4app: M4 binary to sign            [--spl or --m4app is required]"
    echo "  --key-dir: location for key files     [default: ${KEY_DIR}]"
    echo "  --fix-sdp-dcd: turn on clear / restore DCD addr for SPD SPL binary"
    exit 0
fi

if [ -z "${WORK_FILE}" ]; then
    echo "ERROR: must specify either --spl or --m4app"
    echo 1
fi

if [ "${SIGN_M4APP}" = "1" ] && [ "${DCD_CLEAR}" = "1" ]; then
    echo "ERROR: --fix-sdp-dcd is incompatible with --m4app"
    echo 1
fi

if [ "${DCD_CLEAR}" = "1" ]; then
    FIX_SDP_DCD="yes"
else
    FIX_SDP_DCD="no"
fi

echo ""
echo "SETTINGS FOR  : ${0}"
echo "--------------:"
echo "CST BINARY    : ${CST_BINARY}"
echo "CSF TEMPLATE  : ${CSF_TEMPLATE}"
echo "BINARY FILE   : ${WORK_FILE}"
echo "KEYS DIRECTORY: ${KEY_DIR}"
if [ "${SIGN_SPL}" = "1" ]; then
    echo "FIX-SDP-DCD   : ${FIX_SDP_DCD}"
fi
echo ""

# Transform template -> config
sed "s/@@KEY_ROOT@@/${KEY_DIR}/g" ${CSF_TEMPLATE} > ${CSF_TEMPLATE}.csf-config

# working file used for signature
cp ${WORK_FILE} ${WORK_FILE}.mod

# for M4 application: pad binary to 0x1000 alignment
if [ "${SIGN_M4APP}" = "1" ]; then
    BINARY_LEN=$(od -An -t x4 -j 0x1024 -N 0x4 ${WORK_FILE}.mod | cut -d' ' -f2)
    BINARY_LEN=$(printf "%08x" $(((0x${BINARY_LEN} / 0x1000 + 1) * 0x1000)))
    objcopy -I binary -O binary --pad-to 0x${BINARY_LEN} --gap-fill=0x5A ${WORK_FILE}.mod ${WORK_FILE}.mod
fi

# DCD address must be cleared for signature, as SDP will clear it.
if [ "${DCD_CLEAR}" = "1" ]; then
    # generate a NULL address for the DCD
    dd if=/dev/zero of=zero.bin bs=1 count=4
    # replace the DCD address with the NULL address
    dd if=zero.bin of=${WORK_FILE}.mod seek=12 bs=1 conv=notrunc
    rm zero.bin

    # get DCD block info using od, tr and awk
    DCD_START=$(od -An -t x4 -j 0x20 -N 0x4 ${WORK_FILE}.mod | cut -d' ' -f2)
    DCD_HEX=$(od -An -t x4 -j 0x2c -N 0x4 --endian=big ${WORK_FILE} | tr -d ' ' | awk '{print substr($0,3,4)}')
    DCD_LEN=$(printf "0x%08x" 0x${DCD_HEX})
    # hard-code DCD location to bottom of RAM w/ offset of 2c
    DCD_BLOCKS="0x${DCD_START} 0x0000002c ${DCD_LEN}"
    echo "FOUND DCD Blocks ${DCD_BLOCKS}"

    # append DCD block information to CSF config
    echo "[Authenticate Data]" >> ${CSF_TEMPLATE}.csf-config
    echo "Verification index = 2" >> ${CSF_TEMPLATE}.csf-config
    echo "Blocks = ${DCD_BLOCKS} \"${WORK_FILE}.mod\"" >> ${CSF_TEMPLATE}.csf-config
    echo "" >> ${CSF_TEMPLATE}.csf-config
fi

# get HAB block info using od
if [ "${SIGN_M4APP}" = "1" ]; then
	HAB_IVT_SELF=$(od -An -t x4 -j 0x1014 -N 0x4 ${WORK_FILE}.mod | cut -d' ' -f2)
else
	HAB_IVT_SELF=$(od -An -t x4 -j 0x14 -N 0x4 ${WORK_FILE}.mod | cut -d' ' -f2)
fi

# get HAB length using stat
HAB_LEN=$(printf "0x%08x" `stat -c "%s" ${WORK_FILE}.mod`)

# insert CSF offset into m4app binary (as it isn't set by default)
# adjust boot data size to include CSF
if [ "${SIGN_M4APP}" = "1" ]; then
    # remove header from HAB length
    HAB_LEN=$(printf "0x%08x" $((${HAB_LEN} - 0x1000)))
    # insert CSF offset
    HAB_CSF_OFFSET=$(printf "%08x" $((0x${HAB_IVT_SELF} + ${HAB_LEN})))
    # generate binary in bigendian
    HAB_CSF_OFFSET_OCT_1=$(printf "%o" $(echo "$HAB_CSF_OFFSET" | awk '{print "0x"substr($0,7,2)}'))
    HAB_CSF_OFFSET_OCT_2=$(printf "%o" $(echo "$HAB_CSF_OFFSET" | awk '{print "0x"substr($0,5,2)}'))
    HAB_CSF_OFFSET_OCT_3=$(printf "%o" $(echo "$HAB_CSF_OFFSET" | awk '{print "0x"substr($0,3,2)}'))
    HAB_CSF_OFFSET_OCT_4=$(printf "%o" $(echo "$HAB_CSF_OFFSET" | awk '{print "0x"substr($0,1,2)}'))
    printf "\\${HAB_CSF_OFFSET_OCT_1}\\${HAB_CSF_OFFSET_OCT_2}\\${HAB_CSF_OFFSET_OCT_3}\\${HAB_CSF_OFFSET_OCT_4}" > ${WORK_FILE}.csf_offset
    # write the CSF_OFFSET to binary @ 0x1018
    dd if=${WORK_FILE}.csf_offset of=${WORK_FILE}.mod seek=4120 bs=1 conv=notrunc
    rm ${WORK_FILE}.csf_offset

    # increase boot data size to include csf
    BOOT_DATA_SIZE=$(printf "%08x" $((${HAB_LEN} + 0x2000)))
    # generate binary in bigendian
    BOOT_DATA_SIZE_OCT_1=$(printf "%o" $(echo "$BOOT_DATA_SIZE" | awk '{print "0x"substr($0,7,2)}'))
    BOOT_DATA_SIZE_OCT_2=$(printf "%o" $(echo "$BOOT_DATA_SIZE" | awk '{print "0x"substr($0,5,2)}'))
    BOOT_DATA_SIZE_OCT_3=$(printf "%o" $(echo "$BOOT_DATA_SIZE" | awk '{print "0x"substr($0,3,2)}'))
    BOOT_DATA_SIZE_OCT_4=$(printf "%o" $(echo "$BOOT_DATA_SIZE" | awk '{print "0x"substr($0,1,2)}'))
    printf "\\${BOOT_DATA_SIZE_OCT_1}\\${BOOT_DATA_SIZE_OCT_2}\\${BOOT_DATA_SIZE_OCT_3}\\${BOOT_DATA_SIZE_OCT_4}" > ${WORK_FILE}.boot_data
    # write the modified boot_data size to binary @ 0x1024
    dd if=${WORK_FILE}.boot_data of=${WORK_FILE}.mod seek=4132 bs=1 conv=notrunc
    rm ${WORK_FILE}.boot_data
fi

# generate HAB block information
if [ "${SIGN_M4APP}" = "1" ]; then
    # adjust signed length for the offset
    BINARY_LEN=$(printf "0x%08x" $((0x${BINARY_LEN} - 0x1000)))
    HAB_BLOCKS="0x${HAB_IVT_SELF} 0x00001000 ${BINARY_LEN}"
else
    HAB_BLOCKS="0x${HAB_IVT_SELF} 0x00000000 ${HAB_LEN}"
fi
echo "FOUND HAB Blocks ${HAB_BLOCKS}"

# append HAB block information to CSF config
echo "[Authenticate Data]" >> ${CSF_TEMPLATE}.csf-config
echo "Verification index = 2" >> ${CSF_TEMPLATE}.csf-config
# use .mod file in case we cleared DCD info
echo "Blocks = ${HAB_BLOCKS} \"${WORK_FILE}.mod\"" >> ${CSF_TEMPLATE}.csf-config

# generate the signatures, certificates, ... in the CSF binary
${CST_BINARY} --o ${WORK_FILE}_csf.bin --i ${CSF_TEMPLATE}.csf-config

# for m4app binary combine padded .mod file w/ CSF offset written
if [ "${SIGN_M4APP}" = "1" ]; then
    cat ${WORK_FILE}.mod ${WORK_FILE}_csf.bin > ${WORK_FILE}.signed
else
    cat ${WORK_FILE} ${WORK_FILE}_csf.bin > ${WORK_FILE}.signed
fi

# Cleanup config / mod SPL
rm ${CSF_TEMPLATE}.csf-config
rm ${WORK_FILE}_csf.bin
rm ${WORK_FILE}.mod
