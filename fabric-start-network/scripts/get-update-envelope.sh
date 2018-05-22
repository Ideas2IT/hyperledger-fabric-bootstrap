#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

. $(dirname "$0")/env.sh
echo "channel name"
echo $CHANNEL_NAME
org_name="org4"
echo "org name"
echo $org_name
org_msp=${org_name}MSP
org_info_json=${org_name}.json
org_data=$DATA/$org_name
org_update_file_json=${org_name}_update.json
org_update_file=${org_name}_update.pb
org_update_envelope_json=${org_name}_update_envelope.json
org_update_envelope=${org_name}_update_envelope.pb

apt update && apt install jq
rm -rf $org_data
mkdir $org_data
echo "msp"
echo $org_msp
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"'$org_name'":.[1]}}}}}' $DATA/config.json $DATA/$org_info_json > $org_data/modified_config.json
configtxlator proto_encode --input $DATA/config.json --type common.Config --output $org_data/config.pb
configtxlator proto_encode --input $org_data/modified_config.json --type common.Config --output $org_data/modified_config.pb

configtxlator compute_update --channel_id $CHANNEL_NAME --original $org_data/config.pb --updated $org_data/modified_config.pb --output $org_data/$org_update_file
configtxlator proto_decode --input $org_data/$org_update_file --type common.ConfigUpdate | jq . > $org_data/$org_update_file_json

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat $org_data/$org_update_file_json)'}}}' | jq . > $org_data/$org_update_envelope_json

configtxlator proto_encode --input $org_data/$org_update_envelope_json --type common.Envelope --output $org_data/$org_update_envelope
