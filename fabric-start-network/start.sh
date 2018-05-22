#!/bin/bash

set -e

dirname=$(basename $(dirname $0))

if [ ! -d /home/vagrant/go/src/github.com/hyperledger/fabric-samples ]; then
    git clone -b v1.1.0 https://github.com/hyperledger/fabric-samples /home/vagrant/go/src/github.com/hyperledger/fabric-samples
fi

if [[ "$dirname" == "fabric-start-network" ]] || [[ "$dirname" == "fabric-add-organization" ]]; then
    if [[ ! -d "/home/vagrant/$dirname" ]]; then
	cp -a /vagrant/$dirname /home/vagrant/
    fi
    networkDir="/home/vagrant/$dirname"
else
    exit 1
fi

echo $networkDir
cd $networkDir

imgnames=$(docker images -q)
if [[ "$imgnames" == "" ]]; then
    bash ./bootstrap.sh
fi

bash ./makeDocker.sh

function rmContainers {
    local containers="$(docker ps -aq)"
    if [[ "$containers" != "" ]]; then
	docker rm -f $containers
    fi
}

function setupHost {
    hostname=$(hostname)
    
    if [[ "$hostname" == "node0.org0" ]]; then
	rmContainers; cd $networkDir && docker-compose -f docker-compose-$(hostname).yml up -d
	sleep 3 && scp data/org0-ca-cert.pem node1.org0:$networkDir/data/
    elif [[ "$hostname" == "node1.org0" ]]; then
	rmContainers; cd $networkDir && docker-compose -f docker-compose-$(hostname).yml up -d
	sleep 5 && sudo chown -R vagrant:vagrant data
    elif [[ "$hostname" == "node0.org1" ]]; then
	rmContainers; cd $networkDir && docker-compose -f docker-compose-$(hostname).yml up -d
	sleep 5 && scp data/org1-ca-cert.pem node1.org1:$networkDir/data/
    elif [[ "$hostname" == "node1.org1" ]]; then
	rmContainers; cd $networkDir && docker-compose -f docker-compose-$(hostname).yml up -d
	sleep 10 && sudo chown -R vagrant:vagrant data
	rsync -ah data/org1-ca-chain.pem data/orgs node1.org0:$networkDir/data/
	rsync -ah data/org1-ca-chain.pem data/orgs node2.org1:$networkDir/data/
    elif [[ "$hostname" == "node2.org1" ]]; then
	rmContainers; cd $networkDir && docker-compose -f docker-compose-$(hostname).yml up -d
    elif [[ "$hostname" == "node0.org2" ]]; then
	rmContainers; cd $networkDir && docker-compose -f docker-compose-$(hostname).yml up -d
	sleep 5 && scp data/org2-ca-cert.pem node1.org2:$networkDir/data/
    elif [[ "$hostname" == "node1.org2" ]]; then
	rmContainers; cd $networkDir && docker-compose -f docker-compose-$(hostname).yml up -d
	sleep 10 && sudo chown -R vagrant:vagrant data
	rsync -ah data/org2-ca-chain.pem data/orgs node1.org0:$networkDir/data/
	rsync -ah data/org2-ca-chain.pem data/orgs node2.org2:$networkDir/data/
    elif [[ "$hostname" == "node2.org2" ]]; then
	rmContainers; cd $networkDir && docker-compose -f docker-compose-$(hostname).yml up -d
    fi
}

setupHost

# ================================================================================

# node1.org0

# docker-compose -f docker-compose-setup-network.yml up
# docker-compose -f docker-compose-run-network.yml up

# ================================================================================

# Get dump of docker images from one box and load to other boxes:

# On source box:
#    docker save $(docker images --format "{{.Repository}}:{{.Tag}}") | gzip > hyperledger1.1.docker.tgz

# On tgt boxes:
#    docker load < hyperledger1.1.docker.tgz
