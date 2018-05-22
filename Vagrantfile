# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_IMAGE = "fedora/28-cloud-base"

## Initial network setup
## orgname, boxcount for that org.
orgs=[
  ['org0', 2],
  ['org1', 3],
  ['org2', 3],
]

Vagrant.configure("2") do |config|
    config.vm.define  "dnsmasq.local" do |subconfig|
      subconfig.vm.box = BOX_IMAGE
      subconfig.vm.hostname = "dnsmasq.local"
      subconfig.vm.network :private_network, ip: "10.42.0.254", netmask: "16"
      subconfig.vm.provider :libvirt do |libvirt|
        libvirt.storage_pool_name = "img"
        libvirt.cpus = 1
        libvirt.memory = 512
      end
      subconfig.vm.provision "base packages", type: "shell", inline: <<-SHELL
        dnf install -y emacs-nox dnsmasq
      SHELL
      subconfig.vm.provision "code setup", type: "shell", privileged: false, inline: <<-SHELL
        echo -e "export GOPATH=~/go\nexport PATH=$PATH:$GOPATH/bin:~/fabric/bin" >> ~/.bashrc
        . ~/.bashrc
        mkdir ~/go
        mkdir ~/fabric
      SHELL
    end

    config.vm.define  "openvpn.local" do |subconfig|
      subconfig.vm.box = BOX_IMAGE
      subconfig.vm.hostname = "openvpn.local"
      subconfig.vm.network :private_network, ip: "10.42.0.253", netmask: "16"
      subconfig.vm.provider :libvirt do |libvirt|
        libvirt.storage_pool_name = "img"
        libvirt.cpus = 1
        libvirt.memory = 512
      end
      subconfig.vm.provision "base packages", type: "shell", inline: <<-SHELL
        dnf install -y emacs-nox openvpn easy-rsa-3.0.3 bridge-utils
      SHELL
    end

    orgsCounter=0
    orgs.each do |i, j|
      (0..j-1).each do |k|
        config.vm.define  "node#{k}.#{i}" do |subconfig|
          
        subconfig.vm.box = BOX_IMAGE
        subconfig.vm.hostname = "node#{k}.#{i}"
        subconfig.vm.network :private_network, ip: "10.42.0.#{20+orgsCounter}", netmask: "16"
        subconfig.vm.provider :libvirt do |libvirt|
          libvirt.storage_pool_name = "img"
          libvirt.cpus = 1
          libvirt.memory = 512
        end
        subconfig.vm.provision "base packages", type: "shell", inline: <<-SHELL
          dnf install -y emacs-nox nodejs docker docker-compose golang gcc-c++ git libtool-ltdl-devel
          groupadd docker
          usermod -aG docker vagrant
          systemctl enable docker
          systemctl start docker
        SHELL
        subconfig.vm.provision "code setup", type: "shell", privileged: false, inline: <<-SHELL
          echo -e "export GOPATH=~/go\nexport PATH=$PATH:$GOPATH/bin:~/fabric/bin" >> ~/.bashrc
          . ~/.bashrc
          mkdir ~/go
          curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/linux-amd64-1.1.0/hyperledger-fabric-linux-amd64-1.1.0.tar.gz | tar xz
        SHELL
        subconfig.vm.provision "ssh_keys", type: "shell", privileged: false, run: "always", inline: <<-SHELL
          cp -a /vagrant/.ssh/id* /home/vagrant/.ssh/
          cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
        SHELL
        orgsCounter += 1
        end
        config.vm.provision "dns svr", type: "shell", run: "always", inline: <<-SHELL
          echo -e "nameserver 10.42.0.254\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf
        SHELL
      end
    end
    
  # config.vm.provision "setup squid", type: "shell", inline: <<-SHELL
  #   echo "10.42.127.254  download.fedoraproject.org" >> /etc/hosts
  #   cp /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora.repo.orig
  #   cp /etc/yum.repos.d/fedora-updates.repo /etc/yum.repos.d/fedora-updates.repo.orig
  #   cat /etc/yum.repos.d/fedora.repo.orig | sed -E 's/^#baseurl=/baseurl=/' | sed -E 's/^metalink=/#metalink=/' > /etc/yum.repos.d/fedora.repo
  #   cat /etc/yum.repos.d/fedora-updates.repo.orig | sed -E 's/^#baseurl=/baseurl=/' | sed -e 's/\/os//' |sed -E 's/^metalink=/#metalink=/' > /etc/yum.repos.d/fedora-updates.repo
  # SHELL

  config.vm.provision "reset passwords", type: "shell", inline: <<-SHELL
     cp /etc/shadow /etc/shadow.orig
     cat /etc/shadow.orig  | sed -E 's/^root:.*/root:::0:99999:7:::/' | sed -E 's/^vagrant:.*/vagrant:::0:99999:7:::/' > /etc/shadow
     chmod 000 /etc/shadow
     rm /etc/shadow.orig
  SHELL

  config.vm.provision "selinux", type: "shell", run: "always", inline: <<-SHELL
     setenforce 0
  SHELL

  config.vm.provision "emacs", type: "shell", inline: <<-SHELL

    dnf -y install emacs-nox
    exec &> /dev/null
    cat >> ~/.emacs <<EFF
;; melpa
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (url (concat (if no-ssl "http" "https") "://melpa.org/packages/")))
  (add-to-list 'package-archives (cons "melpa" url) t))
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(global-set-key (kbd "M-RET") 'compile)
(global-set-key (kbd "M-s g") 'grep)
(global-set-key (kbd "M-s t") 'toggle-truncate-lines)
(setq grep-command "grep -Irine ")

;; hide menubar and mode line
(menu-bar-mode -1)

;; hooks
(add-hook 'go-mode-hook
          (lambda () (subword-mode 1)))

(add-hook 'protobuf-mode-hook
          (lambda () (subword-mode 1)))

(add-hook 'python-mode-hook
          (lambda () (subword-mode 1)))

EFF

emacs --daemon --eval "(package-refresh-contents)"  --kill
emacs --daemon --eval "(package-install 'go-mode)"  --kill
emacs --daemon --eval "(package-install 'dracula-theme)"  --kill
emacs --daemon --eval "(package-install 'protobuf-mode)"  --kill

echo "(load-theme 'dracula)" >> ~/.emacs

  SHELL
end
