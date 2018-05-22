# hyperledger-fabric-bootstrap

This project gives you a framework for setting up a hyperledger fabric v1.1.0 network on multiple VMs.
We are using Vagrant with libvirt/KVM to create VMs.  Other setups can work too,  with some changes to the Vagrantfile.

## Design

There will be three organizations - org0, org1, org2.  org0 is for the orderer,  and org1 and org2 are participants on the network.
All orgs will have a root CA server running on node0. So node0.org0 is the hostname of org0's root CA server.
node1 on all orgs run an intermediate CA server.  node1.org0 also runs a single orderer,  and node1.org1 and node1.org2 run an anchor/endorsing peer.
org0 does not have a node2.  node2.org1 and node2.org2 run a simple peer.  There is a dnsmasq VM that provides dns resolution to the hosts.

There is an openvpn bridge server on a VM too, VMs created outside the vagrant host can connect to the network through the openvpn server's TAP interface.  We are working on preparing detailed documentation for this.

All these machines are setup to run in the private subnet: 10.42.0.0/16.

We also have a shared squid reverse proxy server for downloading rpm packages from a local cache, because we use disposable VMs a lot.  This blog post explains how such a setup can be created: https://ma.ttwagner.com/lazy-distro-mirrors-with-squid/; If you enable this, you can uncomment the `setup squid` section on the Vagrantfile, update the IP address and all your nodes will start downloading rpm files through squid instead of directly from a mirror every time.

## Instructions

* Clone the repo with

		git clone https://github.com/ideas2it/hyperledger-fabric-bootstrap
	
* Cd into the `hyperledger-fabric-bootstrap` directory, create ssh keys for the VMs to use to recognize each other, then bring up the VMs using below commands.  This would also install docker, emacs, go, etc. on each of the VMs.
    
		cd hyperledger-fabric-bootstrap
		mkdir .ssh
		ssh-keygen -b 4096 -t rsa -N "" -f .ssh/id_rsa    # creates an rsa keypair with no passphrase
		vagrant up dnsmasq.local node0.org{0..2} node1.org{0..2} node2.org{1,2}
	
* Once the machines are up,  run the below command to setup a new copy of the scripts to start the network with.  This is manual because it is needed only when setting up a new network,  not when boxes running nodes are restarted.

		for ii in node0.org{0..2} node1.org{0..2} node2.org{1,2}; do vagrant ssh $ii -c "rm -rf ~/fabric-start-network; cp -a /vagrant/fabric-start-network ~/"; done

* Next we need to setup the IP addresses of the newly created nodes into dnsmasq,  so that nodes can resolve eachother.
  - The dnsmasqHostsFile.bash script prints the hostnames and IP addresses of the newly created nodes.  Run it loke below:

		bash dnsmasqHostsFile.bash
	
  - Login to dnsmasq server using:
  
		vagrant ssh dnsmasq.local
	
  - Append the output of the dnsmasqHostsFile.bash script from above to the end of the /etc/hosts file on dnsmasq.local,  using vi or emacs.
  - Then run these commands in dnsmasq.local to enable and start the dnsmasq service:
  
		sudo systemctl enable dnsmasq
		sudo systemctl start dnsmasq

  - logout of the dnsmasq server,  back to the `hyperledger-fabric-bootstrap` directory on the host machine.

* Next we make sure all nodes have ssh access to all their target nodes (keep typing yes as long as it asks).

	    for ii in node0.org{0..2} node1.org{0..2} node2.org{1,2}; do vagrant ssh $ii -c "bash /vagrant/fabric-start-network/init.sh"; done

* Build the necessary docker images on one VM and copy to others
  - login to node0.org0 first:
  
		vagrant ssh node0.org0
		
  - run below commands on node0.org0 to build the docker images
  
		cd ~/fabric-start-network
		bash bootstrap.sh
		
  - Once the docker images have been downloaded,  use below command on node0.org0 to create a dump of the docker images:
  
        docker save $(docker images --format "{{.Repository}}:{{.Tag}}") | gzip > hyperledger1.1.docker.tgz
		
  - Copy the docker images dump to the host machine,  inside the `hyperledger-fabric-bootstrap` directory,  and reload all the other machines with `vagrant reload`.  That would copy the docker images dump file into the /vagrant/ dir all the VMs.  Then inside each of the VMs,  you can run below command to load the images into docker:
		
		docker load < hyperledger1.1.docker.tgz

  - log out of the VMs

* Now we are ready to start the network.  Run the below command on the host machine,  to start bringing up the docker containers one by one on all the VMs,  and setup the blockchain:

		for ii in node0.org{0..2} node1.org{0..2} node2.org{1,2}; do vagrant ssh $ii -c "bash ~/fabric-start-network/start.sh"; done

* At the end of this,  you should have a running hyperledger fabric v1.1.0 network.
