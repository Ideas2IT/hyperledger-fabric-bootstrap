#!/bin/bash

set -e

dirname=$(basename $(dirname $0))

if [[ "$dirname" != "fabric-start-network" ]] && [[ "$dirname" != "fabric-add-organization" ]]; then
    echo "Running from wrong dir. Please run from within fabric-start-network or fabric-add-organization."
    exit 1
fi

networkDir="/home/vagrant/$dirname"

if [[ -d "$networkDir" ]]; then
    rm -rf "$networkDir"
fi
cp -a /vagrant/$dirname /home/vagrant/

echo "Checking ssh"

function setupSSH {
    local hostname=$(hostname)
    
    if [[ "$hostname" == "node0.org0" ]]; then
	ssh node1.org0 "echo successfully logged in from $hostname to node1.org0"
    elif [[ "$hostname" == "node0.org1" ]]; then
	ssh node1.org1 "echo successfully logged in from $hostname to node1.org1"
    elif [[ "$hostname" == "node1.org1" ]]; then
	ssh node1.org0 "echo successfully logged in from $hostname to node1.org0"
	ssh node2.org1 "echo successfully logged in from $hostname to node2.org1"
    elif [[ "$hostname" == "node0.org2" ]]; then
	ssh node1.org2 "echo successfully logged in from $hostname to node1.org2"
    elif [[ "$hostname" == "node1.org2" ]]; then
	ssh node1.org0 "echo successfully logged in from $hostname to node1.org0"
	ssh node2.org2 "echo successfully logged in from $hostname to node2.org2"
    fi
}

setupSSH
