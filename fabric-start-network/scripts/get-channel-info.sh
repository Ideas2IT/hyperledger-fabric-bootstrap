#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

. $(dirname "$0")/env.sh

IFS=', ' read -r -a OORGS <<< "$ORDERER_ORGS"
IFS=', ' read -r -a PORGS <<< "$PEER_ORGS"

initOrgVars ${OORGS[0]}
initOrdererVars ${OORGS[0]} 1
ORDERER_PORT_ARGS="-o $ORDERER_HOST:7050 --tls --cafile $CA_CHAINFILE"

initPeerVars ${PORGS[0]} 1
switchToAdminIdentity

apt update && apt install jq

CONFIG_BLOCK_FILE=/data/config_block.pb

peer channel fetch config $CONFIG_BLOCK_FILE -c $CHANNEL_NAME  $ORDERER_PORT_ARGS

configtxlator proto_decode --input $CONFIG_BLOCK_FILE --type common.Block > /data/config_block.json   
jq .data.data[0].payload.data.config /data/config_block.json > /data/config.json
