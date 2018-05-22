#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

. $(dirname "$0")/env.sh

IFS=', ' read -r -a OORGS <<< "$ORDERER_ORGS"


initOrdererVars ${OORGS[0]} 1
ORDERER_PORT_ARGS="-o $ORDERER_HOST:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $CA_CHAINFILE"

echo "orderer args"

echo $ORDERER_PORT_ARGS

initOrgVars org0
initPeerVars org0 1
switchToAdminIdentity

peer chaincode install -n mycc -v 2.0 -p github.com/hyperledger/fabric-samples/chaincode/abac

peer chaincode upgrade $ORDERER_PORT_ARGS -C $CHANNEL_NAME -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('org1MSP.member','org2MSP.member','org3MSP.member')"

