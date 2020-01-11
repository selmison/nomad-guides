#!/bin/bash

set -e
cd /ops

CONFIGDIR=/ops/shared/config

CONSULVERSION=1.3.0
CONSULDOWNLOAD=https://releases.hashicorp.com/consul/${CONSULVERSION}/consul_${CONSULVERSION}_linux_amd64.zip
CONSULCONFIGDIR=/etc/consul.d
CONSULDIR=/opt/consul

NOMADVERSION=0.8.6
NOMADDOWNLOAD=https://releases.hashicorp.com/nomad/${NOMADVERSION}/nomad_${NOMADVERSION}_linux_amd64.zip
NOMADCONFIGDIR=/etc/nomad.d
NOMADDIR=/opt/nomad

CNIPLUGINSVERSION=0.8.4
CNIPLUGINSDOWNLOAD=https://github.com/containernetworking/plugins/releases/download/v${CNIPLUGINSVERSION}/cni-plugins-linux-amd64-v${CNIPLUGINSVERSION}.tgz
CNIPLUGINSDIR=/opt/cni


# Dependencies
sudo apt-get install -y software-properties-common
sudo apt-get update
sudo apt-get install -y unzip tree redis-tools jq
sudo apt-get install -y upstart-sysv
sudo update-initramfs -u

# Disable the firewall
sudo ufw disable

# Download Consul
curl -L $CONSULDOWNLOAD > consul.zip

## Install Consul
sudo unzip consul.zip -d /usr/local/bin
sudo chmod 0755 /usr/local/bin/consul
sudo chown root:root /usr/local/bin/consul
sudo setcap "cap_net_bind_service=+ep" /usr/local/bin/consul

## Configure Consul
sudo mkdir -p $CONSULCONFIGDIR
sudo chmod 755 $CONSULCONFIGDIR
sudo mkdir -p $CONSULDIR
sudo chmod 755 $CONSULDIR

# Download Nomad
curl -L $NOMADDOWNLOAD > nomad.zip

## Install Nomad
sudo unzip nomad.zip -d /usr/local/bin
sudo chmod 0755 /usr/local/bin/nomad
sudo chown root:root /usr/local/bin/nomad

## Configure Nomad
sudo mkdir -p $NOMADCONFIGDIR
sudo chmod 755 $NOMADCONFIGDIR
sudo mkdir -p $NOMADDIR
sudo chmod 755 $NOMADDIR

# Docker
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce=17.09.1~ce-0~ubuntu
sudo usermod -aG docker ubuntu

# Download CNI Plugins
curl -L $CNIPLUGINSDOWNLOAD > cni-plugins.tgz

## Install CNI Plugins
sudo mkdir -p $CNIPLUGINSDIR/bin
sudo tar -C $CNIPLUGINSDIR/bin -xzf cni-plugins.tgz

## Configure CNI Plugins
sudo tee /etc/sysctl.d/60-configure-cni-plugins.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
