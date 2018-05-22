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

peer channel update -f $DATA/signed_pb/org4_update_envelope.pb -c $CHANNEL_NAME $ORDERER_PORT_ARGS
